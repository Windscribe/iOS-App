//
//  MainViewController+Siri.swift
//  Windscribe
//
//  Created by Yalcin on 2019-03-25.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import Intents
import IntentsUI

extension MainViewController {
    func setupIntentsForSiri() {
        var shortcuts: [INShortcut] = []

        let interaction = INInteraction(intent: ShowLocationIntent(), response: nil)
        interaction.donate(completion: nil)

        if #unavailable(iOS 17.0) {
            let disconnectActivity = NSUserActivity(activityType: SiriIdentifiers.disconnect)
            disconnectActivity.title = TextsAsset.Siri.disconnectVPN
            disconnectActivity.userInfo = ["speech": "disconnect vpn"]
            disconnectActivity.isEligibleForSearch = true
            disconnectActivity.isEligibleForPrediction = true
            disconnectActivity.persistentIdentifier = NSUserActivityPersistentIdentifier(SiriIdentifiers.disconnect)
            view.userActivity = disconnectActivity
            shortcuts.append(INShortcut(userActivity: disconnectActivity))

            let activity = NSUserActivity(activityType: SiriIdentifiers.connect)
            activity.title = TextsAsset.Siri.connectToVPN
            activity.userInfo = ["speech": "connect to vpn"]
            activity.isEligibleForSearch = true
            activity.isEligibleForPrediction = true
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(SiriIdentifiers.connect)
            view.userActivity = activity
            activity.becomeCurrent()
            shortcuts.append(INShortcut(userActivity: activity))

            INVoiceShortcutCenter.shared.setShortcutSuggestions(shortcuts)
        }
    }

    func displaySiriShortcutPopup() {
        var shortcut: INShortcut?
        if #available(iOS 17.0, *) {
            shortcut = INShortcut(intent: ShowLocationIntent())
        } else {
            guard let userActivity = view.userActivity else { return }
            shortcut = INShortcut(userActivity: userActivity)
        }
        guard let shortcut = shortcut else { return }
        let vc = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
}

extension MainViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith _: INVoiceShortcut?, error _: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
