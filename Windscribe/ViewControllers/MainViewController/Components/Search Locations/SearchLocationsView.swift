//
//  SearchLocationsView.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

class SearchLocationsView: UIView {
    var stackContainerView = UIStackView()
    var searchIcon = UIImageView()
    var searchTextfield = UITextField()
    var clearSearchButton = UIButton()
    var spacerView = UIView()
    var exitSearchButton = ImageButton()

    var viewModel: SearchLocationsViewModelType
    let serverSectionOpacity: Float

    var disposeBag = DisposeBag()

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: SearchLocationsViewModelType, serverSectionOpacity: Float) {
        self.viewModel = viewModel
        self.serverSectionOpacity = serverSectionOpacity
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    func loadView() {
        addViews()
        addViewConstraints()
        bindTextFieldDelegates()
    }

    private func addViews() {
        stackContainerView.axis = .horizontal
        stackContainerView.spacing = 0
        addSubview(stackContainerView)

        searchTextfield.textColor = UIColor.white
        searchTextfield.attributedPlaceholder = NSAttributedString(string: TextsAsset.searchLocations,
                                                                   attributes: [NSAttributedString.Key.foregroundColor: UIColor.whiteWithOpacity(opacity: 0.5)])
        searchIcon.image = UIImage(named: ImagesAsset.search)
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.setImageColor(color: .whiteWithOpacity(opacity: 0.7))

        exitSearchButton.setImage(UIImage(named: ImagesAsset.exitSearch)?.withRenderingMode(.alwaysTemplate)
                                  , for: .normal)
        exitSearchButton.imageView?.setImageColor(color: .whiteWithOpacity(opacity: 0.7))

        var config = UIButton.Configuration.plain()
        config.title = TextsAsset.clearSearch
        config.baseForegroundColor = .cyberBlueWithOpacity(opacity: 0.7)
        config.titleAlignment = .center
        config.titleTextAttributesTransformer =
          UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.text(size: 16)
            return outgoing
          }

        clearSearchButton.configuration = config

        searchTextfield.autocorrectionType = .no
        searchTextfield.autocapitalizationType = .none
        searchTextfield.textColor = UIColor.white
        searchTextfield.returnKeyType = .done
        searchTextfield.attributedPlaceholder = NSAttributedString(string: TextsAsset.searchLocations,
                                                                   attributes: [NSAttributedString.Key.foregroundColor: UIColor.whiteWithOpacity(opacity: 0.5)])
        searchTextfield.font = UIFont.text(size: 14)

        exitSearchButton.imageView?.contentMode = .scaleAspectFit
        exitSearchButton.layer.opacity = serverSectionOpacity

        stackContainerView.addArrangedSubviews([searchIcon, spacerView, searchTextfield, clearSearchButton, exitSearchButton])
    }

    private func addViewConstraints() {
        stackContainerView.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchTextfield.translatesAutoresizingMaskIntoConstraints = false
        clearSearchButton.translatesAutoresizingMaskIntoConstraints = false
        exitSearchButton.translatesAutoresizingMaskIntoConstraints = false
        spacerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stackContainerView
            stackContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackContainerView.heightAnchor.constraint(equalToConstant: 54),

            // spacerView
            spacerView.widthAnchor.constraint(equalToConstant: 16),

            // searchIcon
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),

            // exitSearchButton
            exitSearchButton.widthAnchor.constraint(equalToConstant: 24),
            exitSearchButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func bindTextFieldDelegates() {
        searchTextfield.rx.text
            .subscribe(onNext: { text in
                guard let text = text else { return }
                self.viewModel.searchTextFieldDidChange(text: text)
            })
            .disposed(by: disposeBag)

        searchTextfield.rx.controlEvent(.primaryActionTriggered)
            .subscribe(onNext: { [unowned self] in
                self.searchTextfield.resignFirstResponder()
            })
            .disposed(by: disposeBag)

        clearSearchButton.rx.tap.bind {
            self.clearSearchField()
        }.disposed(by: disposeBag)

        exitSearchButton.rx.tap.bind {
            self.viewModel.toggleSearch()
        }.disposed(by: disposeBag)

        viewModel.isSearchActive.subscribe { isActive in
            self.stackContainerView.isHidden = !isActive
            self.isUserInteractionEnabled = isActive
            if isActive {
                self.searchTextfield.becomeFirstResponder()
            } else {
                self.searchTextfield.resignFirstResponder()
                self.clearSearchField()
            }
        }.disposed(by: disposeBag)
    }

    func setSearchSelected(isSelected: Bool) {
        backgroundColor = isSelected ? .nightBlue : .clear
        isUserInteractionEnabled = isSelected
    }

    private func clearSearchField() {
        searchTextfield.text = ""
        viewModel.searchTextFieldDidChange(text: "")
    }
}
