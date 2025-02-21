//
//  AlertManagerV2.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-01-24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

protocol AlertManagerV2 {
    func showSimpleAlert(viewController: UIViewController?, title: String, message: String, buttonText: String)
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
    func askUser(message: String) -> Single<Bool>
    func askPasswordToDeleteAccount() -> Single<String?>
    func askPasswordToDeleteAccount(viewController: UIViewController) -> Single<String?>
}
