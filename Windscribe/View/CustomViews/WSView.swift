//
//	WSView.swift
//	Windscribe
//
//	Created by Thomas on 27/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

class WSView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        registerNotificationLanguageChanged()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registerNotificationLanguageChanged() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "didChangeLangeguage"), object: nil, queue: .main) { [weak self] _ in
            self?.setupLocalized()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupLocalized()
    }

    func setupLocalized() {

    }
}
