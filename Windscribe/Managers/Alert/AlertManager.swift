//
//  Untitled.swift
//  Windscribe
//
//  Created by Andre Fonseca on 19/01/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//
import UIKit

protocol AlertManager {
    func showSimpleAlert(viewController: UIViewController?, title: String, message: String, buttonText: String)
    func showSimpleAlert(title: String, message: String, buttonText: String)
    func showSimpleAlert(viewController: UIViewController?,
                         title: String,
                         message: String,
                         buttonText: String,
                         completion: @escaping () -> Void)
    func showYesNoAlert(title: String, message: String, completion: @escaping (_ result: Bool) -> Void)
    func showYesNoAlert(viewController: UIViewController,
                        title: String,
                        message: String,
                        completion: @escaping (_ result: Bool) -> Void)
    func showAlert(title: String, message: String, buttonText: String, actions: [UIAlertAction])
    func showAlert(title: String,
                   message: String,
                   actions: [UIAlertAction],
                   preferredAction: UIAlertAction) -> UIAlertController?
    func showAlert(title: String, message: String, actions: [UIAlertAction])
    func showAlert(viewController: UIViewController, title: String, message: String, actions: [UIAlertAction])
    func askUser(message: String, title: String) async -> Bool
    func askPasswordToDeleteAccount() async -> String?
    func askPasswordToDeleteAccount(viewController: UIViewController) async -> String?
}
