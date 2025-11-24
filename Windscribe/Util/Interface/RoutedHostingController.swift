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
    private let lookAndFeelRepository: LookAndFeelRepositoryType = Assembler.resolve(LookAndFeelRepositoryType.self)

    var onPop: (() -> Void)?

    override init(rootView: Content) {
        super.init(rootView: rootView)

        // Set background immediately to prevent white flash during push animation
        view.backgroundColor = UIColor(.from(.screenBackgroundColor, lookAndFeelRepository.isDarkMode))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.backgroundColor = UIColor(.from(.screenBackgroundColor, lookAndFeelRepository.isDarkMode))

        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDarkMode in
                guard let self = self, let navigationBar = self.navigationController?.navigationBar else {
                    return
                }

                let titleColor = UIColor(.from(.titleColor, isDarkMode))
                self.view.backgroundColor = UIColor(.from(.screenBackgroundColor, isDarkMode))

                let appearance = UINavigationBarAppearance().then {
                    $0.configureWithOpaqueBackground()
                    $0.backgroundColor = self.view.backgroundColor
                    $0.titleTextAttributes = [.foregroundColor: titleColor]
                    $0.shadowColor = .clear
                }

                let backButtonAppearance = UIBarButtonItemAppearance().then {
                    $0.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
                    $0.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
                }
                appearance.backButtonAppearance = backButtonAppearance

                // Using a diffrent back button image for Liquid Glass
                let backImageName: String

                if #available(iOS 26.0, *) {
                    backImageName = "back_chevron_glass"
                } else {
                    backImageName = "back_chevron"
                }

                // Template Image created for teh back button diffrent colro modes
                if let templateChevronImage = UIImage(named: backImageName)?.withRenderingMode(.alwaysTemplate) {
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
            }
            .store(in: &cancellables)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        transitionCoordinator?.notifyWhenInteractionChanges { [weak self] context in
            guard let self = self else { return }

            if !context.isCancelled {
                DispatchQueue.main.async {
                    self.onPop?()
                }
            }
        }

        transitionCoordinator?.animate(alongsideTransition: nil, completion: { [weak self] _ in
            guard let self = self else { return }

            let wasPopped = self.navigationController?.viewControllers.contains(self) == false
            if wasPopped {
                DispatchQueue.main.async {
                    self.onPop?()
                }
            }
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)

        if let gesture = navigationController?.interactivePopGestureRecognizer {
            gesture.isEnabled = true
            gesture.delegate = self
        }
    }

    // Ensure the gesture recognizer should begin
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }

}
