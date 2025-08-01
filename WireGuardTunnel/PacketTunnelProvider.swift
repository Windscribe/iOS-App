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
import RxSwift
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

    // MARK: Properties

    private var runningHealthCheck = false
    private var internetAvailable = true
    private let disposeBag = DisposeBag()

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
        NETunnelProviderManager.loadAllFromPreferences { tunnels, _ in
            var wgTunnel: NETunnelProviderManager?
            if let tunnels = tunnels {
                for tunnel in tunnels {
                    if tunnel.protocolConfiguration?.username == "WireGuard" {
                        wgTunnel = tunnel
                    }
                }
            }
            if let wgTunnel = wgTunnel {
                wgTunnel.isOnDemandEnabled = false
                wgTunnel.saveToPreferences() { _ in
                    completionHandler(error)
                }
            } else {
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
        logger.logI("PacketTunnelProvider", "Starting WireGuard Tunnel from the " + (activationAttemptId == nil ? "OS directly, rather than the app" : "app"))
        if !preferences.isCustomConfigSelected() && !wgCrendentials.initialized() {
            apiCallManager.getSession().subscribe(onSuccess: { [weak self] session in
                guard let self = self else { return }
                if session.status == 1 {
                    self.logger.logI("PacketTunnelProvider", "User status is Okay, attempt rebuilding credentials.")
                    self.runningHealthCheck = true
                    self.requestNewInterfaceIp(completionHandler: completionHandler)
                } else {
                    self.logger.logI("PacketTunnelProvider", "User status is \(session.status), do not reconnect.")
                    stopTunnel(completionHandler: completionHandler)
                }
            }, onFailure: { error in
                let errorDescription: String
                if let wsError = error as? Errors {
                    errorDescription = wsError.unlocalizedDescription
                } else {
                    errorDescription = error.localizedDescription
                }
                self.logger.logE("PacketTunnelProvider", "Error getting user session: \(errorDescription)")
                completionHandler(error)
            }).disposed(by: disposeBag)
            return
        }

        guard let tunnelProviderProtocol = protocolConfiguration as? NETunnelProviderProtocol,
              var tunnelConfiguration = tunnelProviderProtocol.asTunnelConfiguration()
        else {
            errorNotifier.notify(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        // Tunnel configuration provided with start of connection may have changed due user status change.
        let lastIpAddress = tunnelConfiguration.interface.addresses[0].stringRepresentation
        if !preferences.isCustomConfigSelected() && lastIpAddress != wgCrendentials.address {
            tunnelConfiguration = try! TunnelConfiguration(fromWgQuickConfig: wgCrendentials.asWgCredentialsString() ?? "")
        }
        if ConnectedDNSType(value: preferences.getConnectedDNS()) == .custom {
            let customDNSValue = preferences.getCustomDNSValue()
            logger.logI("PacketTunnelProvider", "User DNS configuration: \(customDNSValue.description)")
            if let dnsSettings = DNSSettingsManager.makeDNSSettings(from: customDNSValue) {
                tunnelConfiguration.dnsSettings = dnsSettings
            }
        }
        adapter.start(tunnelConfiguration: tunnelConfiguration) { adapterError in
            guard let adapterError = adapterError else {
                let interfaceName = self.adapter.interfaceName ?? "unknown"
                self.logger.logI("PacketTunnelProvider", "Tunnel interface is \(interfaceName)")
                #if os(iOS)
                    WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                #endif
                completionHandler(nil)
                return
            }

            switch adapterError {
            case .cannotLocateTunnelFileDescriptor:
                self.logger.logE("PacketTunnelProvider", "Starting tunnel failed: could not determine file descriptor")
                errorNotifier.notify(PacketTunnelProviderError.couldNotDetermineFileDescriptor)
                completionHandler(PacketTunnelProviderError.couldNotDetermineFileDescriptor)

            case let .dnsResolution(dnsErrors):
                let hostnamesWithDnsResolutionFailure = dnsErrors.map { $0.address }
                    .joined(separator: ", ")
                self.logger.logE("PacketTunnelProvider", "DNS resolution failed for the following hostnames: \(hostnamesWithDnsResolutionFailure)")
                errorNotifier.notify(PacketTunnelProviderError.dnsResolutionFailure)
                completionHandler(PacketTunnelProviderError.dnsResolutionFailure)

            case let .setNetworkSettings(error):
                self.logger.logE("PacketTunnelProvider", "Starting tunnel failed with setTunnelNetworkSettings returning \(error.localizedDescription)")
                errorNotifier.notify(PacketTunnelProviderError.couldNotSetNetworkSettings)
                completionHandler(PacketTunnelProviderError.couldNotSetNetworkSettings)

            case let .startWireGuardBackend(errorCode):
                self.logger.logE("PacketTunnelProvider", "Starting tunnel failed with wgTurnOn returning \(errorCode)")
                errorNotifier.notify(PacketTunnelProviderError.couldNotStartBackend)
                completionHandler(PacketTunnelProviderError.couldNotStartBackend)

            case .invalidState:
                // Must never happen
                fatalError()
            }
        }
    }

    override func stopTunnel(with _: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.logI("PacketTunnelProvider", "Stopping WireGuard tunnel.")
        adapter.stop { error in
            ErrorNotifier.removeLastErrorFile()

            if let error = error {
                self.logger.logE("PacketTunnelProvider", "Failed to stop WireGuard adapter: \(error.localizedDescription)")
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
            logger.logI("PacketTunnelProvider", "Device wake up.")
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
            logger.logI("PacketTunnelProvider", "Running health connection health check.")
            DispatchQueue.global().async {
                self.runningHealthCheck = true
                self.getSession()
            }
        }
    }

    /// Request new interface ip from wg init + wg connect
    /// Check if interface changed or peer changed (Account status change.)
    private func setNewTunnelInterfaceIp(updatedConfig: TunnelConfiguration) {
        logger.logI("PacketTunnelProvider", "Interface has address changed")
        reasserting = true
        replacePeer(tunnelConfiguration: updatedConfig)
    }

    /// Check user session for change.
    func getSession() {
        // Ensure LocalizationBridge is initialized before potential error handling
        ensureLocalizationInitialized()
        logger.logI("PacketTunnelProvider", "Requesting user session update.")
        apiCallManager.getSession()
            .subscribe(onSuccess: { [self] data in
                if data.status == 1 {
                    self.requestNewInterfaceIp()
                } else {
                    self.runningHealthCheck = false
                    wgCrendentials.delete()
                    preferences.saveForceDisconnect(value: true)
                    self.logger.logI("PacketTunnelProvider", "User status is banned/expired")
                    self.cancelTunnelWithError(NSError(domain: "com.windscribe", code: 50))
                }
            }, onFailure: { error in
                self.runningHealthCheck = false
                if let wsError = error as? Errors {
                    self.logger.logE("PacketTunnelProvider", "Get Session failed with Windscribe error - \(wsError.unlocalizedDescription).")
                    switch wsError {
                    case Errors.sessionIsInvalid:
                        self.wgCrendentials.delete()
                        self.cancelTunnelWithError(NSError(domain: "com.windscribe", code: 50))
                    case let Errors.apiError(e):
                        self.logger.logE("PacketTunnelProvider", "Get Session failed with API error - \(e.errorMessage ?? "").")
                    default:
                        self.runningHealthCheck = false
                    }
                }
            }).disposed(by: disposeBag)
    }

    /// Request new interface address to check if it has changed.
    private func requestNewInterfaceIp(completionHandler: ((Error?) -> Void)? = nil) {
        // Ensure LocalizationBridge is initialized before any potential error handling
        ensureLocalizationInitialized()
        do {
            var tunnelConfig: TunnelConfiguration? = nil
            if let config = wgCrendentials.asWgCredentialsString(), wgCrendentials.initialized() {
                tunnelConfig = try TunnelConfiguration(fromWgQuickConfig: config)
            }
            let lastIpAddress = tunnelConfig?.interface.addresses[0].stringRepresentation ?? ""
            let oldKey = wgCrendentials.presharedKey
            wgConfigRepository.getCredentials().subscribe(onCompleted: {
                self.runningHealthCheck = false
                // Restart extesnion if connection to apply new configuration.
                if let completionHandler = completionHandler {
                    completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
                    return
                }
                if let newAddress = self.wgCrendentials.address, let key = self.wgCrendentials.presharedKey {
                    if newAddress != lastIpAddress || oldKey != key {
                        do {
                            let updatedConfig = try TunnelConfiguration(fromWgQuickConfig: self.wgCrendentials.asWgCredentialsString()!)
                            if ConnectedDNSType(value: self.preferences.getConnectedDNS()) == .custom {
                                let customDNSValue = self.preferences.getCustomDNSValue()
                                self.logger.logI("PacketTunnelProvider", "User DNS configuration: \(customDNSValue.description)")
                                if let dnsSettings = DNSSettingsManager.makeDNSSettings(from: customDNSValue) {
                                    updatedConfig.dnsSettings = dnsSettings
                                }
                            }
                            self.setNewTunnelInterfaceIp(updatedConfig: updatedConfig)
                        } catch {
                            self.logger.logE("PacketTunnelProvider", "Failed to get wg configuration: \(error.localizedDescription)")
                        }
                    }
                }
            }, onError: { error in
                self.runningHealthCheck = false
                let errorDesc: String
                if let wsError = error as? Errors {
                    errorDesc = wsError.unlocalizedDescription
                } else {
                    errorDesc = error.localizedDescription
                }
                self.logger.logE("PacketTunnelProvider", "Failed to build get wg configuration from api: \(errorDesc)")
                if let completionHandler = completionHandler {
                    completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
                    return
                }
            }).disposed(by: disposeBag)
        } catch let e {
            self.logger.logE("PacketTunnelProvider", "Failed to get wg configuration. \(e.localizedDescription)")
            self.runningHealthCheck = false
            if let completionHandler = completionHandler {
                completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
                return
            }
        }
    }

    // Generates and apply updated wg config. Only do if peer changes (Private key + preshaed key changed)
    private func replacePeer(tunnelConfiguration: TunnelConfiguration) {
        adapter.update(tunnelConfiguration: tunnelConfiguration) { error in
            if let error = error {
                self.logger.logE("PacketTunnelProvider", "Error updating tunnel configuration. \(error)")
            }
            self.reasserting = false
        }
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
