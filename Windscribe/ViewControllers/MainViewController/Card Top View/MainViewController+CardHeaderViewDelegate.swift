//
//  MainViewController+CardHeaderViewDelegate.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject

extension MainViewController {
    func addCardHeaderView() {
        cardHeaderContainerView = Assembler.resolve(CardHeaderContainerView.self)
        cardHeaderContainerView.viewModel.delegate = self
        view.addSubview(cardHeaderContainerView)
        cardHeaderContainerView.loadView()
        addCardHeaderViewConstraints()
    }

    private func addCardHeaderViewConstraints() {
        cardHeaderContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardHeaderContainerView.topAnchor.constraint(equalTo: cardView.topAnchor),
            cardHeaderContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardHeaderContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardHeaderContainerView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

extension MainViewController: CardHeaderContainerViewDelegate {
    func cardHeaderWasSelected(with type: CardHeaderButtonType) {
        lastSelectedHeaderViewTab = type
        switch type {
        case .all:
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        case .fav:
            scrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: true)
        case .flix:
            scrollView.setContentOffset(CGPoint(x: self.view.frame.width*2, y: 0), animated: true)
        case .staticIP:
            scrollView.setContentOffset(CGPoint(x: self.view.frame.width*3, y: 0), animated: true)
        case .config:
            scrollView.setContentOffset(CGPoint(x: self.view.frame.width*4, y: 0), animated: true)
        case.startSearch:
            searchLocationsView.viewModel.toggleSearch()
        }
    }
}
