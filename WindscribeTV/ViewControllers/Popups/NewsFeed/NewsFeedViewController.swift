//
//  NewsFeedViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 22/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class NewsFeedViewController: UIViewController {
    @IBOutlet weak var listStackView: UIStackView!
    @IBOutlet weak var buttonContainerView: UIStackView!
    @IBOutlet weak var buttonHiddingView: UIView!
    @IBOutlet weak var newsBodyText: UITextView!
    var button = WSPillButton()
    
    var viewModel: NewsFeedModelType!, logger: FileLogger!, router: HomeRouter!
    let disposeBag = DisposeBag()
    var currentAction: NoticeAction?
    
    private var newsSections = [NewsSection]()
    
    //MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindViews()
    }
    
    //MARK: Setting up
    private func setup() {
        button.setup(withHeight: 96)
        buttonContainerView.addArrangedSubview(button)
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
            let newsNameView: OptionSelectionView = PreferencesOptionView.fromNib()
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

extension NewsFeedViewController: OptionSelectionViewDelegate {
    func optionWasSelected(_ sender: OptionSelectionView) {
        guard let index = listStackView.arrangedSubviews.firstIndex(of: sender), newsSections.count >= index
        else { return }
        guard let details = newsSections[index-1].items.first else { return }
        setupDetailsView(with: details)
        listStackView.arrangedSubviews.forEach {
            if let view = $0 as? OptionSelectionView {
                view.updateSelection(with: view == sender)
            }
        }
    }
}
