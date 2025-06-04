//
//  RoutedHostingController.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject
import Combine

class RoutedHostingController<Content: View>: UIHostingController<Content> {
    private var cancellables = Set<AnyCancellable>()

    var onPop: (() -> Void)?

    override func viewDidLoad() {
        let lookAndFeelRepository = Assembler.resolve(LookAndFeelRepositoryType.self)

        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.navigationController?.navigationBar.tintColor = .white
            }, receiveValue: { [weak self] isDarkMode in
                let color: Color = .from(.titleColor, isDarkMode)
                self?.navigationController?.navigationBar.tintColor = UIColor(color)
                self?.navigationController?.navigationBar.titleTextAttributes = [
                        .foregroundColor: UIColor(color)
                    ]
            })
            .store(in: &cancellables)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            onPop?()
        }
    }
}
