//
//  AlertManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-18.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject

class AlertManagerImpl: AlertManager {
    private lazy var windowProvider: WindowProvider = Assembler.resolve(WindowProvider.self)

    func showSimpleAlert(title: String, message: String, buttonText: String) {
        showSimpleAlert(viewController: nil,
                        title: title,
                        message: message,
                        buttonText: buttonText)
    }

    func showSimpleAlert(viewController: UIViewController? = nil, title: String, message: String, buttonText: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonText, style: .default, handler: nil)
            alert.addAction(action)
            self.presentAlertOnViewController(alert: alert, viewController: viewController)
        }
    }

    func showSimpleAlert(viewController: UIViewController?,
                         title: String,
                         message: String,
                         buttonText: String,
                         completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            let action = UIAlertAction(title: buttonText,
                                       style: .default,
                                       handler: { _ in
                                            completion()
                                       })

            alert.addAction(action)
            self.presentAlertOnViewController(alert: alert, viewController: viewController)
        }
    }

    func showYesNoAlert(viewController: UIViewController, title: String, message: String, completion: @escaping (_ result: Bool) -> Void) {
        showYesNoAlertDefault(viewController: viewController, title: title, message: message, completion: completion)
    }

    func showYesNoAlert(title: String, message: String, completion: @escaping (_ result: Bool) -> Void) {
        showYesNoAlertDefault(title: title, message: message, completion: completion)
    }

    private func showYesNoAlertDefault(viewController: UIViewController? = nil, title: String, message: String, completion: @escaping (_ result: Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            let yesAction = UIAlertAction(title: TextsAsset.yes, style: .default,
                                          handler: { _ in
                                              completion(true)
                                          })
            let noAction = UIAlertAction(title: TextsAsset.no,
                                         style: .cancel,
                                         handler: { _ in
                                             completion(false)
                                         })
            alert.addAction(yesAction)
            alert.addAction(noAction)
            self.presentAlertOnViewController(alert: alert, viewController: viewController)
        }
    }

    func showAlert(title: String, message: String, buttonText: String, actions: [UIAlertAction]) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let simpleAction = UIAlertAction(title: buttonText, style: .default, handler: nil)
            for action in actions {
                alert.addAction(action)
            }
            alert.addAction(simpleAction)
            self.presentAlertOnViewController(alert: alert)
        }
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction], preferredAction: UIAlertAction) -> UIAlertController? {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }
        alert.preferredAction = preferredAction
        presentAlertOnViewController(alert: alert)
        return alert
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            for action in actions {
                alert.addAction(action)
            }
            self.presentAlertOnViewController(alert: alert)
        }
    }

    func showAlert(viewController: UIViewController, title: String, message: String, actions: [UIAlertAction]) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            for action in actions {
                alert.addAction(action)
            }
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    @MainActor
    func askUser(message: String, title: String = TextsAsset.error) async -> Bool {
        return await withCheckedContinuation { continuation in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let positiveAction = UIAlertAction(title: TextsAsset.okay, style: .default, handler: { _ in
                continuation.resume(returning: true)
            })
            alert.addAction(positiveAction)
            let negativeAction = UIAlertAction(title: TextsAsset.cancel, style: .cancel, handler: { _ in
                continuation.resume(returning: false)
            })
            alert.addAction(negativeAction)
            guard let window = windowProvider.mainWindow, let viewController = window.rootViewController else { return }
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    private func presentAlertOnViewController(alert: UIAlertController, viewController: UIViewController? = nil) {
        if viewController == nil {
            guard let window = windowProvider.mainWindow,
                let viewController = window.activeViewController else {
                    return
            }
            viewController.present(alert, animated: true, completion: nil)
        } else {
            viewController?.present(alert, animated: true, completion: nil)
        }
    }

    func askPasswordToDeleteAccount(viewController: UIViewController) async -> String? {
        return await askPasswordToDeleteAccountDefault(viewController: viewController)
    }

    func askPasswordToDeleteAccount() async -> String? {
        return await askPasswordToDeleteAccountDefault()
    }

    @MainActor
    private func askPasswordToDeleteAccountDefault(viewController: UIViewController? = nil) async -> String? {
        return await withCheckedContinuation { continuation in
            let alert = UIAlertController(title: TextsAsset.Account.cancelAccount, message: TextsAsset.Account.deleteAccountMessage, preferredStyle: .alert)
            alert.addTextField { field in
                field.layer.cornerRadius = 3
                field.clipsToBounds = true
                field.font = UIFont.text(size: 16)
                field.autocorrectionType = .no
                field.autocapitalizationType = .none
            }
            let positiveAction = UIAlertAction(title: TextsAsset.okay, style: .default, handler: { _ in
                continuation.resume(returning: alert.textFields?[0].text ?? nil)
            })
            alert.addAction(positiveAction)
            let negativeAction = UIAlertAction(title: TextsAsset.cancel, style: .cancel, handler: { _ in
                continuation.resume(returning: nil)
            })
            alert.addAction(negativeAction)
            var presentingController: UIViewController?
            if let viewController = viewController {
                presentingController = viewController
            } else {
                guard let window = windowProvider.mainWindow, let viewController = window.rootViewController else { return }
                presentingController = viewController
            }
            presentingController?.present(alert, animated: true, completion: nil)
        }
    }
}
