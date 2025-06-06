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

class RoutedHostingController<Content: View>: UIHostingController<Content>, UIGestureRecognizerDelegate {
    private var cancellables = Set<AnyCancellable>()

    var onPop: (() -> Void)?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let lookAndFeelRepository = Assembler.resolve(LookAndFeelRepositoryType.self)

        view.backgroundColor = UIColor(.from(.actionBackgroundColor, lookAndFeelRepository.isDarkMode))

        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in}, receiveValue: { [weak self] isDarkMode in
                guard let self = self, let navigationBar = self.navigationController?.navigationBar else {
                    return
                }

                let titleColor = UIColor(.from(.titleColor, isDarkMode))
                let navigationBarBackgroundColor = UIColor(.from(.screenBackgroundColor, isDarkMode))

                let appearance = UINavigationBarAppearance().then {
                    $0.configureWithOpaqueBackground()
                    $0.backgroundColor = navigationBarBackgroundColor
                    $0.titleTextAttributes = [.foregroundColor: titleColor]
                    $0.shadowColor = .clear
                }

                let backButtonAppearance = UIBarButtonItemAppearance().then {
                    $0.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
                    $0.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
                }
                appearance.backButtonAppearance = backButtonAppearance

                if let templateChevronImage = UIImage(named: "back_chevron")?.withRenderingMode(.alwaysTemplate) {
                    let colorChevron = templateChevronImage.withTintColor(titleColor, renderingMode: .alwaysOriginal)
                    appearance.setBackIndicatorImage(colorChevron, transitionMaskImage: templateChevronImage)
                }

                navigationBar.do {
                    $0.tintColor = titleColor
                    $0.standardAppearance = appearance
                    $0.scrollEdgeAppearance = appearance
                    $0.compactAppearance = appearance
                    $0.compactScrollEdgeAppearance = appearance
                }

                navigationBar.do {
                    $0.setNeedsLayout()
                    $0.layoutIfNeeded()
                }
            })
            .store(in: &cancellables)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            onPop?()
        }
    }

    // Ensure the gesture recognizer should begin
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }

}
