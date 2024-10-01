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
        [ShowLocationIntent(), ConnectIntent(), DisconnectIntent()].forEach {
            let interaction = INInteraction(intent: $0, response: nil)
            interaction.donate(completion: nil)
        }
    }

    func displaySiriShortcutPopup() {
        guard let userActivity = view.userActivity else { return }
        let shortcut = INShortcut(userActivity: userActivity)
        let vc = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }

}

extension MainViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
