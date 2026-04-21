//
//  MockAlertManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//
import Foundation
import UIKit
@testable import Windscribe

class MockAlertManager: AlertManager {
    var askUserCalled = false
    var lastMessage: String?
    var userResponse = false

    func askUser(message: String, title: String = TextsAsset.error) async -> Bool {
        askUserCalled = true
        lastMessage = message
        return userResponse
    }

    func askPasswordToDeleteAccount() async -> String? {
        return nil
    }

    func askPasswordToDeleteAccount(viewController: UIViewController) async -> String? {
        return nil
    }

    func showSimpleAlert(viewController: UIViewController?, title: String, message: String, buttonText: String) {
        // No-op for tests
    }

    func showSimpleAlert(title: String, message: String, buttonText: String) {
        // No-op for tests
    }

    func showSimpleAlert(viewController: UIViewController?, title: String, message: String, buttonText: String, completion: @escaping () -> Void) {
        // No-op for tests
    }

    func showYesNoAlert(title: String, message: String, completion: @escaping (_ result: Bool) -> Void) {
        // No-op for tests
    }

    func showYesNoAlert(viewController: UIViewController, title: String, message: String, completion: @escaping (_ result: Bool) -> Void) {
        // No-op for tests
    }

    func showAlert(title: String, message: String, buttonText: String, actions: [UIAlertAction]) {
        // No-op for tests
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction], preferredAction: UIAlertAction) -> UIAlertController? {
        return nil
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        // No-op for tests
    }

    func showAlert(viewController: UIViewController, title: String, message: String, actions: [UIAlertAction]) {
        // No-op for tests
    }

    func reset() {
        askUserCalled = false
        lastMessage = nil
        userResponse = false
    }
}
