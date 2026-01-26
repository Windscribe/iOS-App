//
//  PacketTunnelProvider.swift
//  WireGuardTunnel
//
//  Created by Yalcin on 2020-06-29.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation
import Network
import NetworkExtension
import os.log
import Swinject
import WireGuardKit
#if canImport(WidgetKit)
    import WidgetKit
#endif

class PacketTunnelProvider: NEPacketTunnelProvider {
    // MARK: dependencies

    private lazy var container: Container = {
        let container = Container(isExt: true)
        return container
    }()

    private lazy var wgCrendentials: WgCredentials = container.resolve(WgCredentials.self)!

    private lazy var wgConfigRepository: WireguardConfigRepository = container.resolve(WireguardConfigRepository.self)!

    private lazy var apiCallManager: WireguardAPIManager = container.resolve(WireguardAPIManager.self)!

    private lazy var preferences: Preferences = container.resolve(Preferences.self)!

    private lazy var logger: FileLogger = {
        let logger = container.resolve(FileLogger.self)!
        return logger
    }()

    private lazy var dnsSettingsManager: DNSSettingsManagerType = container.resolve(DNSSettingsManagerType.self)!

    // MARK: Properties

    private var runningHealthCheck = false
    private var internetAvailable = true

    private lazy var adapter: WireGuardAdapter = .init(with: self) { _, message in
        if message.contains("Retrying handshake") {
            self.onStaleConnection()
        }
    }


    override init() {
        super.init()
        // Ensure LocalizationBridge is initialized for network extension context
        ensureLocalizationInitialized()
    }

    private func ensureLocalizationInitialized() {
        if LocalizationBridge.needsSetup {
            let localizationService = LocalizationServiceImpl(logger: logger)
            LocalizationBridge.setup(localizationService)
        }
    }

    private func stopTunnel(completionHandler: @escaping (Error?) -> Void) {
        let error = NSError(domain: "com.windscribe", code: 50)
        NETunnelProviderManager.loadAllFromPreferences { tunnels, loadError in
            var wgTunnel: NETunnelProviderManager?

            if let loadError = loadError {
                self.logger.logE("PacketTunnelProvider", "Error loading tunnel preferences: \(loadError.localizedDescription)", flushImmediately: true)
                completionHandler(loadError)
                return
            }

            if let tunnels = tunnels {
                // Filter out any nil objects to prevent crashes
                let validTunnels = tunnels.compactMap { $0 }
                self.logger.logI("PacketTunnelProvider", "Loaded \(validTunnels.count) valid tunnels out of \(tunnels.count) total")

                for tunnel in validTunnels {
                    if tunnel.protocolConfiguration?.username == "WireGuard" {
                        wgTunnel = tunnel
                        break
                    }
                }
            } else {
                self.logger.logI("PacketTunnelProvider", "No tunnels loaded from preferences")
            }

            if let wgTunnel = wgTunnel {
                wgTunnel.isOnDemandEnabled = false
                wgTunnel.saveToPreferences() { saveError in
                    if let saveError = saveError {
                        self.logger.logE("PacketTunnelProvider", "Error saving tunnel preferences: \(saveError.localizedDescription)", flushImmediately: true)
                    }
                    completionHandler(error)
                }
            } else {
                self.logger.logI("PacketTunnelProvider", "No WireGuard tunnel found", flushImmediately: true)
                completionHandler(error)
            }
        }
    }

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let activationAttemptId = options?["activationAttemptId"] as? String
        let errorNotifier = ErrorNotifier(activationAttemptId: activationAttemptId)

        ensureLocalizationInitialized()

        // Load configuration from preferences.
        wgCrendentials.load()
        logger.logI("PacketTunnelProvider", "Starting WireGuard Tunnel from the " + (activationAttemptId == nil ? "OS directly, rather than the app" : "app"), flushImmediately: true)
        if !preferences.isCustomConfigSelected() && !wgCrendentials.initialized() {
            completionHandler(NSError(domain: "com.windscribe", code: 50))
            return
        }

        self.logger.logI("PacketTunnelProvider", "Passed wg credentials initialzed check.", flushImmediately: true)

        guard let tunnelProviderProtocol = protocolConfiguration as? NETunnelProviderProtocol,
              var tunnelConfiguration = tunnelProviderProtocol.asTunnelConfiguration()
        else {
            self.logger.logE("PacketTunnelProvider", "Saved Protocol Configuration is invalid - nil", flushImmediately: true)
            errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        // Ensure tunnel configuration is up to date with latest credentials
        if !preferences.isCustomConfigSelected() {
            do {
                tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: wgCrendentials.asWgCredentialsString() ?? "")
                logger.logI("PacketTunnelProvider", "Created tunnel configuration from wgQuickConfig", flushImmediately: true)
            } catch {
                logger.logE("PacketTunnelProvider", "Failed to create tunnel configuration: \(error)", flushImmediately: true)
                errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
                completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
                return
            }
        }
        if ConnectedDNSType(value: preferences.getConnectedDNS()) == .custom {
            let customDNSValue = preferences.getCustomDNSValue()
            logger.logI("PacketTunnelProvider", "User DNS configuration: \(customDNSValue.description)", flushImmediately: true)
            if let dnsSettings = dnsSettingsManager.makeDNSSettings(from: customDNSValue) {
                tunnelConfiguration.dnsSettings = dnsSettings
            }
        }
        adapter.start(tunnelConfiguration: tunnelConfiguration) { adapterError in
            guard let adapterError = adapterError else {
                let interfaceName = self.adapter.interfaceName ?? "unknown"
                self.logger.logI("PacketTunnelProvider", "Tunnel interface is \(interfaceName)", flushImmediately: true)
                #if os(iOS)
                    WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                #endif
                completionHandler(nil)
                return
            }

            switch adapterError {
            case .cannotLocateTunnelFileDescriptor:
                self.logger.logE("PacketTunnelProvider", "Starting tunnel failed: could not determine file descriptor", flushImmediately: true)
                errorNotifier.notify(PacketTunnelProviderError.couldNotDetermineFileDescriptor)
                completionHandler(PacketTunnelProviderError.couldNotDetermineFileDescriptor)

            case let .dnsResolution(dnsErrors):
                let hostnamesWithDnsResolutionFailure = dnsErrors.map { $0.address }
                    .joined(separator: ", ")
                self.logger.logE("PacketTunnelProvider", "DNS resolution failed for the following hostnames: \(hostnamesWithDnsResolutionFailure)", flushImmediately: true)
                errorNotifier.notify(PacketTunnelProviderError.dnsResolutionFailure)
                completionHandler(PacketTunnelProviderError.dnsResolutionFailure)

            case let .setNetworkSettings(error):
                self.logger.logE("PacketTunnelProvider", "Starting tunnel failed with setTunnelNetworkSettings returning \(error.localizedDescription)", flushImmediately: true)
                errorNotifier.notify(PacketTunnelProviderError.couldNotSetNetworkSettings)
                completionHandler(PacketTunnelProviderError.couldNotSetNetworkSettings)

            case let .startWireGuardBackend(errorCode):
                self.logger.logE("PacketTunnelProvider", "Starting tunnel failed with wgTurnOn returning \(errorCode)", flushImmediately: true)
                errorNotifier.notify(PacketTunnelProviderError.couldNotStartBackend)
                completionHandler(PacketTunnelProviderError.couldNotStartBackend)

            case .invalidState:
                // Must never happen
                fatalError()
            }
        }
    }

    override func stopTunnel(with _: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.logI("PacketTunnelProvider", "Stopping WireGuard tunnel.", flushImmediately: true)
        adapter.stop { error in
            ErrorNotifier.removeLastErrorFile()

            if let error = error {
                self.logger.logE("PacketTunnelProvider", "Failed to stop WireGuard adapter: \(error.localizedDescription)", flushImmediately: true)
            }
            completionHandler()

            #if os(macOS)
                // HACK: This is a filthy hack to work around Apple bug 32073323 (dup'd by us as 47526107).
                // Remove it when they finally fix this upstream and the fix has been rolled out to
                // sufficient quantities of users.
                exit(0)
            #endif
        }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        guard let completionHandler = completionHandler else { return }

        if messageData.count == 1 && messageData[0] == 0 {
            adapter.getRuntimeConfiguration { settings in
                var data: Data?
                if let settings = settings {
                    data = settings.data(using: .utf8)!
                }
                completionHandler(data)
            }
        } else {
            completionHandler(nil)
        }
    }

    override func wake() {
        let currentTime = Date().timeIntervalSince1970
        let lastWakeTime = preferences.getWireguardWakeupTime()
        if lastWakeTime == 0 || currentTime - lastWakeTime >= 600 {
            logger.logI("PacketTunnelProvider", "Device wake up.", flushImmediately: true)
            UserDefaults.standard.set(currentTime, forKey: "lastWakeTime")
            preferences.saveWireguardWakeupTime(value: currentTime)
            onStaleConnection()
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    /// Called when handshake fails. Checks user status and authentication.
    func onStaleConnection() {
        if !runningHealthCheck && !preferences.isCustomConfigSelected() {
            logger.logI("PacketTunnelProvider", "Running health connection health check.", flushImmediately: true)
            DispatchQueue.global().async {
                self.runningHealthCheck = true
                self.getSession()
            }
        }
    }

    /// Check user session for change.
    func getSession() {
        // Ensure LocalizationBridge is initialized before potential error handling
        ensureLocalizationInitialized()
        logger.logI("PacketTunnelProvider", "Requesting user session update.", flushImmediately: true)
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let data = try await apiCallManager.getSession()
                if data.status != 1 {
                    disconnect()
                }
                self.runningHealthCheck = false
            } catch {
                self.runningHealthCheck = false
                if let wsError = error as? Errors {
                    self.logger.logE("PacketTunnelProvider", "Get Session failed with Windscribe error - \(wsError.unlocalizedDescription).", flushImmediately: true)
                    switch wsError {
                    case Errors.sessionIsInvalid:
                      disconnect()
                    case let Errors.apiError(e):
                        self.logger.logE("PacketTunnelProvider", "Get Session failed with API error - \(e.errorMessage ?? "").", flushImmediately: true)
                    default:
                        self.runningHealthCheck = false
                    }
                }
            }
        }
    }

    private func disconnect() {
        self.wgCrendentials.delete()
        self.cancelTunnelWithError(NSError(domain: "com.windscribe", code: 50))
        self.logger.logE("PacketTunnelProvider", "Get Session failed with API because session is invalid - code 50.", flushImmediately: true)
    }
}

extension WireGuardLogLevel {
    var osLogLevel: OSLogType {
        switch self {
        case .verbose:
            return .debug
        case .error:
            return .error
        }
    }
}
