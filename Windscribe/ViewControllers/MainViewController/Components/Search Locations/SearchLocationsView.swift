//
//  SearchLocationsView.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Combine
import Foundation
import UIKit

class SearchLocationsView: UIView {
    var stackContainerView = UIStackView()
    var searchIcon = UIImageView()
    var searchTextfield = UITextField()
    var clearSearchButton = UIButton()
    var spacerView = UIView()
    var separatorView = UIView()
    var exitSearchButton = ImageButton()
    lazy var clearExitButtonWidthConstraint: NSLayoutConstraint = {
        clearSearchButton.widthAnchor.constraint(equalToConstant: 80)
    }()

    var viewModel: SearchLocationsViewModelType
    let locationSectionOpacity: Float
    let clearButtonFont = UIFont.text(size: 16)
    private var isDarkMode: Bool = DefaultValues.darkMode

    private var cancellables = Set<AnyCancellable>()

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: SearchLocationsViewModelType, locationSectionOpacity: Float) {
        self.viewModel = viewModel
        self.locationSectionOpacity = locationSectionOpacity
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        bindViews()
    }

    func loadView() {
        addViews()
        addViewConstraints()
        bindTextFieldDelegates()
    }

    private func bindViews() {
        viewModel.isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDarkMode in
                guard let self = self else { return }
                separatorView.backgroundColor = .from(.gradientBorderColor, isDarkMode)
                searchTextfield.textColor = .from(.textColor, isDarkMode)
                updateSearchTextfield(for: isDarkMode)
                searchIcon.setImageColor(color: .from(.infoColor, isDarkMode))
                exitSearchButton.imageView?.setImageColor(color: .from(.infoColor, isDarkMode))
                searchTextfield.textColor = .from(.textColor, isDarkMode)
                backgroundColor = isUserInteractionEnabled ? .from(.backgroundColor, isDarkMode) : .clear
                self.isDarkMode = isDarkMode
            }
            .store(in: &cancellables)

        viewModel.refreshLanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                clearSearchButton.configuration = getClearConfig()
                let isDarkMode = viewModel.isDarkMode.value
                updateSearchTextfield(for: isDarkMode)

                let title = TextsAsset.clearSearch
                let width = title.size(withAttributes: [.font: clearButtonFont]).width
              clearExitButtonWidthConstraint.constant = width + 26
              layoutIfNeeded()
            }
            .store(in: &cancellables)
    }

    private func addViews() {
        addSubview(separatorView)
        separatorView.isHidden = true
        stackContainerView.axis = .horizontal
        stackContainerView.alignment = .center
        stackContainerView.spacing = 0
        addSubview(stackContainerView)

        searchIcon.image = UIImage(named: ImagesAsset.search)
        searchIcon.contentMode = .scaleAspectFit

        exitSearchButton.setImage(UIImage(named: ImagesAsset.exitSearch)?.withRenderingMode(.alwaysTemplate)
                                  , for: .normal)

        clearSearchButton.configuration = getClearConfig()

        searchTextfield.autocorrectionType = .no
        searchTextfield.autocapitalizationType = .none
        searchTextfield.returnKeyType = .done
        searchTextfield.font = UIFont.text(size: 14)

        exitSearchButton.imageView?.contentMode = .scaleAspectFit
        exitSearchButton.layer.opacity = locationSectionOpacity

        stackContainerView.addArrangedSubviews([searchIcon, spacerView, searchTextfield, clearSearchButton, exitSearchButton])
    }

    private func getClearConfig() -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.title = TextsAsset.clearSearch
        config.baseForegroundColor = .cyberBlueWithOpacity(opacity: 0.7)
        config.titleAlignment = .center
        config.titleTextAttributesTransformer =
          UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
              outgoing.font = self.clearButtonFont
            return outgoing
          }
        return config
    }

    private func updateSearchTextfield(for isDarkMode: Bool) {
        searchTextfield.attributedPlaceholder = NSAttributedString(string: TextsAsset.searchLocations,
                                                                   attributes: [NSAttributedString.Key.foregroundColor: UIColor.from(.placeholderColor, isDarkMode)])
    }

    private func addViewConstraints() {
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        stackContainerView.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchTextfield.translatesAutoresizingMaskIntoConstraints = false
        clearSearchButton.translatesAutoresizingMaskIntoConstraints = false
        exitSearchButton.translatesAutoresizingMaskIntoConstraints = false
        spacerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // separatorView
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),

            // stackContainerView
            stackContainerView.bottomAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 1),
            stackContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackContainerView.heightAnchor.constraint(equalToConstant: 54),

            // spacerView
            spacerView.widthAnchor.constraint(equalToConstant: 16),

            // searchIcon
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),

            // exitSearchButton
            clearExitButtonWidthConstraint,

            // exitSearchButton
            exitSearchButton.widthAnchor.constraint(equalToConstant: 24),
            exitSearchButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func bindTextFieldDelegates() {
        searchTextfield.textEditedPublisher
            .sink { [weak self] text in
                self?.viewModel.searchTextFieldDidChange(text: text)
            }
            .store(in: &cancellables)

        searchTextfield.wasSelected
            .sink { [weak self] _ in
                self?.searchTextfield.resignFirstResponder()
            }
            .store(in: &cancellables)

        clearSearchButton.tap
            .sink { [weak self] _ in
                self?.clearSearchField()
            }
            .store(in: &cancellables)

        exitSearchButton.tap
            .sink { [weak self] _ in
                self?.viewModel.toggleSearch()
            }
            .store(in: &cancellables)

        viewModel.isSearchActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                guard let self = self else { return }
                self.stackContainerView.isHidden = !isActive
                self.isUserInteractionEnabled = isActive
                if isActive {
                    self.searchTextfield.becomeFirstResponder()
                } else {
                    self.searchTextfield.resignFirstResponder()
                    self.clearSearchField()
                }
            }
            .store(in: &cancellables)
    }

    func setSearchSelected(isSelected: Bool) {
        backgroundColor = isSelected ? .from(.backgroundColor, isDarkMode) : .clear
        isUserInteractionEnabled = isSelected
        separatorView.isHidden = !isSelected
    }

    private func clearSearchField() {
        searchTextfield.text = ""
        viewModel.searchTextFieldDidChange(text: "")
    }
}
