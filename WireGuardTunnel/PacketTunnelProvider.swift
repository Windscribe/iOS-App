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
import os
import Swinject
import WireGuardKit
#if canImport(WidgetKit)
    import WidgetKit
#endif

class PacketTunnelProvider: NEPacketTunnelProvider, TunnelCredentialsManaging {
    // MARK: dependencies

    private lazy var container: Container = {
        let container = Container(isExt: true)
        return container
    }()

    private lazy var wgCrendentials: WgCredentials = container.resolve(WgCredentials.self)!

    private lazy var apiUtil: APIUtilService = container.resolve(APIUtilService.self)!

    private lazy var api: WSNetServerAPIType = container.resolve(WSNetServerAPIType.self)!

    private lazy var preferences: Preferences = container.resolve(Preferences.self)!

    private lazy var logger: FileLogger = {
        let logger = container.resolve(FileLogger.self)!
        return logger
    }()

    private let consoleLogger = Logger(subsystem: "Windscribe-tunnel", category: "com.windscribe.vpn")
    private lazy var dnsSettingsManager: DNSSettingsManagerType = container.resolve(DNSSettingsManagerType.self)!

    // MARK: Properties

    private var internetAvailable = true
    private var controlPlane: ControlPlane?
    private var isCancelling = false

    private lazy var adapter: WireGuardAdapter = .init(with: self) { _, message in
        if message.contains("Retrying handshake") {
            if self.preferences.getDisconnectReason() == DisconnectReason.unknown {
                self.controlPlane?.checkTunnelHealth()
            }
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
            guard let quickConfig = wgCrendentials.asWgCredentialsString() else {
                logger.logE("PacketTunnelProvider", "WG credentials incomplete (base IPv4 fields missing); refusing to start tunnel", flushImmediately: true)
                errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
                completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
                return
            }
            do {
                tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: quickConfig)
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

                // Initialize control plane when tunnel is ready
                self.controlPlane = ControlPlane(
                    apiUtil: self.apiUtil,
                    api: self.api,
                    preferences: self.preferences,
                    consoleLogger: self.consoleLogger,
                    onTunnelShouldStop: { @MainActor [weak self] reason, error in
                        guard let self = self else { return }
                        self.logger.logI("PacketTunnelProvider", "Control plane requested tunnel stop for reason: \(reason.rawValue)", flushImmediately: true)
                        self.deleteCredentials(error: error)
                    }
                )


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
                completionHandler(PacketTunnelProviderError.couldNotStartBackend)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.logI("PacketTunnelProvider", "Stopping WireGuard tunnel with reason \(reason.rawValue).", flushImmediately: true)
        if reason == .appUpdate {
            preferences.saveTunnelStoppedForAppUpdate(status: true)
        }
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
            if preferences.getDisconnectReason() == DisconnectReason.unknown {
                controlPlane?.checkTunnelHealth()
            }
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        logger.logI("PacketTunnelProvider", "Device going to sleep.", flushImmediately: true)
        completionHandler()
    }

    // MARK: - TunnelCredentialsManaging

    @MainActor
    func deleteCredentials(error: NSError) {
        guard !isCancelling else {
            logger.logI("PacketTunnelProvider", "Already cancelling tunnel, ignoring duplicate call.", flushImmediately: true)
            return
        }
        controlPlane = nil
        isCancelling = true
        logger.logI("PacketTunnelProvider", "Deleted WireGuard credentials.", flushImmediately: true)
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
