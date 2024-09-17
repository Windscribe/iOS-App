//
//  NewsFeedViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 22/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class NewsFeedViewController: PreferredFocusedViewController {
    @IBOutlet weak var listStackView: UIStackView!
    @IBOutlet weak var buttonContainerView: UIStackView!
    @IBOutlet weak var buttonHiddingView: UIView!
    @IBOutlet weak var newsBodyText: UITextView!
    @IBOutlet weak var titleLabel: UILabel!

    var button = WSPillButton()

    var viewModel: NewsFeedModelType!, logger: FileLogger!, router: HomeRouter!
    let disposeBag = DisposeBag()
    var currentAction: NoticeAction?

    private var newsSections = [NewsSection]()

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Notifications View")
        setup()
        bindViews()
    }

    // MARK: Setting up
    private func setup() {
        button.setup(withHeight: 96)
        buttonContainerView.addArrangedSubview(button)
        setupSwipeRightGesture()
        titleLabel.text = TextsAsset.NewsFeed.title
        titleLabel.font = UIFont.bold(size: 72)
        titleLabel.textColor = .white
    }

    private func bindViews() {
        viewModel.newsSections.subscribe { [weak self] newsSections in
            guard let self = self else { return }
            buildSelectionOptions(newsSections: newsSections)
        }.disposed(by: disposeBag)
        button.rx.primaryAction.bind { _ in
            guard let action = self.currentAction else { return }
            self.router.routeTo(to: .upgrade(promoCode: action.promoCode, pcpID: action.pcpid), from: self)
        }.disposed(by: disposeBag)
    }

    private func buildSelectionOptions(newsSections: [NewsSection]) {
        self.newsSections = newsSections
        let firstItem = self.newsSections.first?.items.first
        newsSections.forEach {
            let newsNameView: OptionSelectionView = OptionSelectionView.fromNib()
            if let details = $0.items.first {
                self.listStackView.addArrangedSubview(newsNameView)
                newsNameView.setup(with: details.title ?? "", isSelected: firstItem?.title == details.title)
                newsNameView.delegate = self
            }
        }
        guard let firstItem = firstItem else { return }
        self.setupDetailsView(with: firstItem)
    }

    private func setupDetailsView(with item: NewsFeedCellViewModel) {
        if let message = item.message, let messageData = message.data(using: .utf8) {
            newsBodyText.htmlText(htmlData: messageData,
                              font: .regular(size: 42),
                                  foregroundColor: .white)
        }
        if let action = item.action {
            button.setTitle(action.label, for: .normal)
            buttonHiddingView.isHidden = false
            currentAction = action
        } else {
            currentAction = nil
            buttonHiddingView.isHidden = true
        }
    }
}

// MARK: Touches and Keys handling
extension NewsFeedViewController {
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            super.pressesBegan(presses, with: event)
            if press.type == .rightArrow, updateBodyButtonFocus() {
                break
            }
        }
    }

    private func setupSwipeRightGesture() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended, updateBodyButtonFocus() { return }
    }

    private func updateBodyButtonFocus() -> Bool {
        if button != UIScreen.main.focusedView {
            myPreferredFocusedView = button
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
            return true
        }
        return false
    }
}

extension NewsFeedViewController: OptionSelectionViewDelegate {
    func optionWasSelected(_ sender: OptionSelectionView) {
        guard let index = listStackView.arrangedSubviews.firstIndex(of: sender), newsSections.count >= index
        else { return }
        guard let details = newsSections[index-1].items.first else { return }
        logger.logD(self, "Pressed to see details of \(details.title ?? "No title").")
        setupDetailsView(with: details)
        listStackView.arrangedSubviews.forEach {
            if let view = $0 as? OptionSelectionView {
                view.updateSelection(with: view == sender)
            }
        }
    }
}
