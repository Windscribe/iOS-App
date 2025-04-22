//
//  ListHeaderView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

enum ListHeaderViewType {
    case staticIP, customConfig, favNodes

    var description: String {
        switch self {
        case .staticIP:
            return "Static IPs"
        case .customConfig:
            return "Custom Configs"
        case .favNodes:
            return "Favorite Locations"
        }
    }
}

class ListHeaderView: UIView {
    let isDarkMode: BehaviorSubject<Bool>
    let type: ListHeaderViewType

    let disposeBag = DisposeBag()
    let infoLabel = UILabel()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(type: ListHeaderViewType, isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        self.type = type
        super.init(frame: .zero)
        addViews()
        setLayout()

        isDarkMode.subscribe { isDarkMode in
            self.updateLayourForTheme(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
    }

    private func updateLayourForTheme(isDarkMode: Bool) {
        backgroundColor = isDarkMode ? .nightBlue : .white
        infoLabel.textColor = isDarkMode ? UIColor.whiteWithOpacity(opacity: 0.7) : .nightBlue
    }

    private func addViews() {
        backgroundColor = .clear
        infoLabel.font = UIFont.regular(size: 12)
        infoLabel.text = type.description
        addSubview(infoLabel)
    }

    private func setLayout() {
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // infoView
            widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            heightAnchor.constraint(equalToConstant: 40),

            // infoLabel
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 5),
            infoLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            infoLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        ])
    }
}
