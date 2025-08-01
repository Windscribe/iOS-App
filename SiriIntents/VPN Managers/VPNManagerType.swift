//
//  VPNManagerType.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

enum VPNManagerUserName: String {
    case openVPN = "OpenVPN"
    case wireGuard = "WireGuard"
}

protocol VPNManagerType: AnyObject {
    var setupCompleted: Bool { get set }
    var logger: FileLogger { get }
    var kcDb: KeyChainDatabase { get }
    func setup(completion: @escaping () -> Void)
    func isConfigured() -> Bool
    func isConnected() -> Bool
    func isDisconnected() -> Bool
    func removeProfile(completion: @escaping (_ result: Bool, _ error: String?) -> Void)
    func connect(otherProviders: [VPNManagerType], completion: @escaping (_ result: Bool) -> Void)
    func disconnect(completion: @escaping (_ result: Bool) -> Void)

    func getProviderManager() -> NEVPNManager?
}

extension VPNManagerType {
    func isConnected() -> Bool {
        return getProviderManager()?.connection.status == .connected
    }

    func isConnecting() -> Bool {
        return getProviderManager()?.connection.status == .connecting
    }

    func isDisconnected() -> Bool {
        return getProviderManager()?.connection.status == .disconnected
    }

    func removeProfile(completion: @escaping (_ result: Bool, _ error: String?) -> Void) {
        let providerManager = getProviderManager()
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
            guard let self = self else { return }
            if self.isConfigured() {
                self.disconnect { _ in }
                providerManager?.removeFromPreferences { _ in
                    providerManager?.loadFromPreferences(completionHandler: { _ in
                        self.setupCompleted = false
                        self.setup {
                            completion(true, nil)
                        }
                    })
                }
            } else {
                completion(true, nil)
            }
        })
    }

    func connect(otherProviders: [VPNManagerType], completion: @escaping (_ result: Bool) -> Void) {
        let providerManager = getProviderManager()
        for otherProvider in otherProviders {
            if otherProvider.isConnected() {
                otherProvider.disconnect { _ in }
                completion(false)
                continue
            }
        }
        if !isConnected(), !isConnecting() {
            removeOtherProfiles(otherProviders: otherProviders) { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    logger.logE("VPNManagerType", "Error removing profile: \(error)")
                    completion(false)
                    return
                }
                providerManager?.loadFromPreferences { error in
                    if let error = error {
                        self.logger.logE("VPNManagerType", "Error loading profile: \(error)")
                        completion(false)
                        return
                    }
                    if result {
                        providerManager?.isOnDemandEnabled = DefaultValues.firewallMode
                        providerManager?.isEnabled = true
                        providerManager?.saveToPreferences { error in
                            if let error = error {
                                self.logger.logE("VPNManagerType", "Error saving profile: \(error)")
                                completion(false)
                                return
                            }
                            providerManager?.loadFromPreferences(completionHandler: { error in
                                if let error = error {
                                    self.logger.logE("VPNManagerType", "Error loading profile: \(error)")
                                    completion(false)
                                    return
                                }
                                do {
                                    try providerManager?.connection.startVPNTunnel()
                                    self.logger.logD("VPNManagerType", "Tunnel started successfully with \(providerManager.debugDescription).")
                                } catch let e {
                                    self.logger.logE("VPNManagerType", "Error starting tunnel: \(e)")
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        }
                    } else { completion(false) }
                }
            }
        } else { completion(false) }
    }

    func disconnect(completion: @escaping (_ result: Bool) -> Void) {
        let providerManager = getProviderManager()
        if isDisconnected() { completion(false); return }
        providerManager?.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            if error == nil, self.isConfigured() {
                providerManager?.isOnDemandEnabled = false
                providerManager?.isEnabled = false
                providerManager?.saveToPreferences { _ in
                    providerManager?.loadFromPreferences(completionHandler: { _ in
                        providerManager?.connection.stopVPNTunnel()
                        completion(true)
                    })
                }
            } else { completion(false) }
        }
    }

    private func removeOtherProfiles(otherProviders: [VPNManagerType], _ result: Bool = true, _ error: String? = nil, completion: @escaping (_ result: Bool, _ error: String?) -> Void) {
        guard !otherProviders.isEmpty else { completion(result, error); return }
        var providers = otherProviders
        providers.removeFirst().removeProfile { [weak self] result, error in
            guard result, error == nil, let self = self else { completion(result, error); return }
            self.removeOtherProfiles(otherProviders: providers, result, error, completion: completion)
        }
    }
}
