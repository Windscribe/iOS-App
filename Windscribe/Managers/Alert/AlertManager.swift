//
//  AlertManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-18.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class AlertManager: AlertManagerV2 {

    static let shared = AlertManager()

    func showSimpleAlert(viewController: UIViewController? = nil, title: String, message: String, buttonText: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonText, style: .default, handler: nil)
            alert.addAction(action)
            self.presentAlertOnViewController(alert: alert, viewController: viewController)
        }
    }

    func showYesNoAlert(title: String, message: String, completion: @escaping (_ result: Bool) -> Void) {
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
            self.presentAlertOnViewController(alert: alert)
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
        self.presentAlertOnViewController(alert: alert)
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

    func askUser(message: String) -> Single<Bool> {
        return Single<Bool>.create { completion in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: TextsAsset.error, message: message, preferredStyle: .alert)
                let positiveAction = UIAlertAction(title: TextsAsset.okay, style: .default, handler: { _ in
                    completion(.success(true))
                })
                alert.addAction(positiveAction)
                let negativeAction = UIAlertAction(title: TextsAsset.cancel, style: .cancel, handler: { _ in
                    completion(.success(false))
                })
                alert.addAction(negativeAction)
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window, let viewController = window.rootViewController else { return }
                viewController.present(alert, animated: true, completion: nil)
            }
            return Disposables.create()
        }
      }

    func getLoadingAlert() -> UIAlertController {
        let loadingAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: loadingAlert.view.bounds)
        loadingIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingIndicator.color = UIColor.black
        loadingAlert.view.addSubview(loadingIndicator)
        loadingIndicator.isUserInteractionEnabled = false
        loadingIndicator.startAnimating()
        return loadingAlert
    }

    private func presentAlertOnViewController(alert: UIAlertController ,viewController: UIViewController? = nil) {
        if viewController == nil {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window, let viewController = window.rootViewController else { return }
            viewController.present(alert, animated: true, completion: nil)
        } else {
            viewController?.present(alert, animated: true, completion: nil)
        }
    }
}
