//
//  NewsFeedViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 22/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class NewsFeedViewController: PreferredFocusedViewController {
    @IBOutlet var listStackView: UIStackView!
    @IBOutlet var buttonContainerView: UIStackView!
    @IBOutlet var buttonHiddingView: UIView!
    @IBOutlet var newsBodyText: UITextView!
    @IBOutlet var titleLabel: UILabel!

    var button = WSPillButton()

    var viewModel: NewsFeedModelType!, logger: FileLogger!, router: HomeRouter!, alertManager: AlertManagerV2!
    let disposeBag = DisposeBag()
    var selectedActionLink: ActionLink?

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
        viewModel.newsfeedData.bind { data in
            self.newsBodyText.isHidden = true
            self.buttonHiddingView.isHidden = true
            if let firstItem = data.first {
                self.newsBodyText.isHidden = false
                data.forEach { feed in
                    let newsNameView: OptionSelectionView = OptionSelectionView.fromNib()
                    newsNameView.setup(with: feed.title, isSelected: firstItem.title == feed.title)
                    newsNameView.delegate = self
                    self.listStackView.addArrangedSubview(newsNameView)
                }
                self.setupDetailsView(with: firstItem)
            }
        }.disposed(by: disposeBag)

        viewModel.viewToLaunch.bind(onNext: { view in
            switch view {
                case let .safari(url):
                    self.logger.logD("NewsFeed", "Opening url in safari: \(url)")
                    self.alertManager.showSimpleAlert(viewController: self, title: "", message: "No browser found to open URL. Use iOS app instead.", buttonText: TextsAsset.okay)
                case let .payment(promo, pcpid):
                    self.logger.logD("NewsFeed", "Launching payment plans with promo: \(promo)")
                    self.router.routeTo(to: .upgrade(promoCode: promo, pcpID: pcpid), from: self)
                default: ()
            }
        }).disposed(by: disposeBag)
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
            setNeedsFocusUpdate()
            updateFocusIfNeeded()
            return true
        }
        return false
    }

    private func setupDetailsView(with item: NewsFeedData) {
        newsBodyText.text = item.description
        if let action = item.actionLink {
            button.setTitle(action.title, for: .normal)
            buttonHiddingView.isHidden = false
            selectedActionLink = action
            button.addTapGesture(tapNumber: 1, target: self, action: #selector(onActionClick))
        } else {
            selectedActionLink = nil
            buttonHiddingView.isHidden = true
        }
    }

    @objc private func onActionClick() {
        if let action = selectedActionLink {
            viewModel.didTapAction(action: action)
        }
    }
}

extension NewsFeedViewController: OptionSelectionViewDelegate {
    func optionWasSelected(_ sender: OptionSelectionView) {
        let sections = (try? viewModel.newsfeedData.value()) ?? []
        guard let index = listStackView.arrangedSubviews.firstIndex(of: sender), sections.count >= index
        else { return }
        let details = sections[index-1]
        logger.logD(self, "Pressed to see details of \(details.title).")
        setupDetailsView(with: details)
        for arrangedSubview in listStackView.arrangedSubviews {
            if let view = arrangedSubview as? OptionSelectionView {
                view.updateSelection(with: view == sender)
            }
        }
    }
}
