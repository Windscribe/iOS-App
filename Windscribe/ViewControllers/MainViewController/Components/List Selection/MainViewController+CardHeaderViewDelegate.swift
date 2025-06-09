//
//  MainViewController+CardHeaderViewDelegate.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

extension MainViewController {
    func addCardHeaderView() {
        listSelectionView = Assembler.resolve(ListSelectionView.self)
        listSelectionView.viewModel.delegate = self
        view.addSubview(listSelectionView)
        listSelectionView.loadView()
    }
}

extension MainViewController: ListSelectionViewDelegate {
    func cardHeaderWasSelected(with type: CardHeaderButtonType) {
        lastSelectedHeaderViewTab = type
        listSelectionView.viewModel.setSelectedAction(selectedAction: type)
        ipInfoView.viewModel.updateCardHeaderType(with: type)
        switch type {
        case .all:
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        case .fav:
            scrollView.setContentOffset(CGPoint(x: view.frame.width, y: 0), animated: true)
        case .staticIP:
            scrollView.setContentOffset(CGPoint(x: view.frame.width * 2, y: 0), animated: true)
        case .config:
            scrollView.setContentOffset(CGPoint(x: view.frame.width * 3, y: 0), animated: true)
        case .startSearch:
            searchLocationsView.viewModel.toggleSearch()
        }
    }
}
