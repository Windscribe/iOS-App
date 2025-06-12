//
//  SubmitTicketViewController+UI.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-24.
//  Copyright © 2021 Windscribe. All rights reserved.
//
import IQKeyboardManagerSwift
import RxSwift
import UIKit

extension SubmitTicketViewController: UITextViewDelegate, UITextFieldDelegate {
    func bindViews() {
        viewModel.isDarkMode.subscribe(on: MainScheduler.instance).subscribe {
            self.setupViews(isDark: $0)
            self.setupUI(isDark: $0)
        }.disposed(by: disposeBag)

        Observable.combineLatest(continueButtonEnabledSubject.asObservable(), viewModel.isDarkMode.asObservable()).bind { isEnabled, isDarkMode in
            self.continueButton.backgroundColor = isEnabled ? UIColor.seaGreen : (isDarkMode ? UIColor.midnightWithOpacity(opacity: 0.10) : UIColor.whiteWithOpacity(opacity: 0.10))
        }.disposed(by: disposeBag)
    }

    func addViews() {
        descriptionView = UILabel()
        descriptionView.text = TextsAsset.SubmitTicket.fillInTheFields
        descriptionView.font = UIFont.text(size: 12)
        descriptionView.layer.opacity = 0.5
        descriptionView.textColor = UIColor.white
        descriptionView.numberOfLines = 2

        descriptionContentView = UIView()
        descriptionContentView.layer.cornerRadius = 8
        descriptionContentView.layer.borderWidth = 2
        descriptionContentView.addSubview(descriptionView)
        view.addSubview(descriptionContentView)

        categoryContentView = UIView()
        categoryContentView.layer.cornerRadius = 8
        view.addSubview(categoryContentView)

        categoryView = UILabel()
        categoryView.text = TextsAsset.SubmitTicket.category
        categoryView.font = UIFont.bold(size: 16)
        categoryView.textColor = UIColor.white
        view.addSubview(categoryView)

        catergoryDropDownView = DropdownButton(isDarkMode: viewModel.isDarkMode)
        catergoryDropDownView.delegate = self
        catergoryDropDownView.setTitle(TextsAsset.SubmitTicket.categories[0])
        catergoryDropDownView.isUserInteractionEnabled = true
        view.addSubview(catergoryDropDownView)

        divider1 = UIView()
        divider1.layer.opacity = 0.05
        divider1.backgroundColor = UIColor.white
        view.addSubview(divider1)

        yourEmailView = UILabel()
        yourEmailView.text = TextsAsset.SubmitTicket.email
        yourEmailView.font = UIFont.bold(size: 16)
        yourEmailView.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        view.addSubview(yourEmailView)

        emailRequiredView = UILabel()
        emailRequiredView.text = "(\(TextsAsset.SubmitTicket.required))"
        emailRequiredView.layer.opacity = 0.5
        emailRequiredView.textColor = UIColor.white
        emailRequiredView.font = UIFont.text(size: 16)
        view.addSubview(emailRequiredView)

        emailInputView = AuthenticationTextField(isDarkMode: viewModel.isDarkMode)
        emailInputView.text = viewModel.sessionManager.session?.email
        emailInputView.addTarget(self, action: #selector(fieldsValueChanged), for: .editingChanged)
        emailInputView.layer.cornerRadius = 24
        emailInputView.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.addSubview(emailInputView)

        emailExplainerView = UILabel()
        emailExplainerView.text = TextsAsset.SubmitTicket.soWeCanContactYou
        emailExplainerView.font = UIFont.text(size: 12)
        emailExplainerView.layer.opacity = 0.5
        emailExplainerView.numberOfLines = 2
        emailExplainerView.textColor = UIColor.white
        view.addSubview(emailExplainerView)

        subjectTitleView = UILabel()
        subjectTitleView.text = TextsAsset.SubmitTicket.subject
        subjectTitleView.font = UIFont.bold(size: 16)
        subjectTitleView.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        view.addSubview(subjectTitleView)

        subjectRequiredView = UILabel()
        subjectRequiredView.text = "(\(TextsAsset.SubmitTicket.required))"
        subjectRequiredView.layer.opacity = 0.5
        subjectRequiredView.textColor = UIColor.white
        subjectRequiredView.font = UIFont.text(size: 16)
        view.addSubview(subjectRequiredView)

        subjectInputView = AuthenticationTextField(isDarkMode: viewModel.isDarkMode)
        subjectInputView.addTarget(self, action: #selector(fieldsValueChanged), for: .editingChanged)
        subjectInputView.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        subjectInputView.delegate = self
        subjectInputView.layer.cornerRadius = 24
        view.addSubview(subjectInputView)

        messageTitleView = UILabel()
        messageTitleView.text = TextsAsset.SubmitTicket.whatsTheMatter
        messageTitleView.font = UIFont.bold(size: 16)
        messageTitleView.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        view.addSubview(messageTitleView)

        messageRequiredView = UILabel()
        messageRequiredView.text = "(\(TextsAsset.SubmitTicket.required))"
        messageRequiredView.layer.opacity = 0.5
        messageRequiredView.textColor = UIColor.white
        messageRequiredView.font = UIFont.text(size: 16)
        view.addSubview(messageRequiredView)

        messageInputView = UITextView()
        messageInputView.font = UIFont.text(size: 16)
        messageInputView.toolbarPlaceholder = "Message".localized
        messageInputView.delegate = self
        messageInputView.isEditable = true
        messageInputView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        messageInputView.layer.cornerRadius = 8
        view.addSubview(messageInputView)

        continueButton = UIButton()
        continueButton.setTitleColor(UIColor.whiteWithOpacity(opacity: 0.5), for: .normal)
        continueButton.titleLabel?.font = UIFont.text(size: 16)
        continueButton.addTarget(self, action: #selector(continueSendTicketTapped), for: .touchUpInside)
        continueButton.layer.cornerRadius = 26
        continueButton.clipsToBounds = true
        continueButton.backgroundColor = UIColor.seaGreen
        let buttonTitle = "Send".localized
        // TextsAsset.continue)
        let attributedTitle = NSMutableAttributedString(string: buttonTitle)
        continueButton.setAttributedTitle(attributedTitle, for: .normal)
        view.addSubview(continueButton)
        disableContinueButton()

        loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.color = .gray
        view.addSubview(loadingView)

        successMessageView = UILabel()
        successMessageView.isHidden = true
        successMessageView.numberOfLines = 3
        successMessageView.text = TextsAsset.SubmitTicket.weWillGetBackToYou
        successMessageView.font = UIFont.text(size: 16)
        successMessageView.textColor = UIColor.white
        successMessageView.layer.opacity = 0.5
        successMessageView.textAlignment = NSTextAlignment.center
        view.addSubview(successMessageView)

        successIconView = UIImageView()
        successIconView.isHidden = true
        successIconView.contentMode = .scaleAspectFit
        successIconView.image = UIImage(named: ImagesAsset.Help.success)
        view.addSubview(successIconView)
    }

    func showProgressView() {
        let attributedTitle = NSMutableAttributedString(string: "")
        continueButton.setAttributedTitle(attributedTitle, for: .normal)
        loadingView.isHidden = false
    }

    func hideProgressView() {
        loadingView.isHidden = true
        let attributedTitle = NSMutableAttributedString(string: TextsAsset.continue)
        continueButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    func showSuccessView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hideProgressView()
            self.descriptionView.isHidden = true
            self.descriptionContentView.isHidden = true
            self.categoryContentView.isHidden = true
            self.categoryView.isHidden = true
            self.divider1.isHidden = true
            self.yourEmailView.isHidden = true
            self.emailRequiredView.isHidden = true
            self.emailInputView.isHidden = true
            self.emailExplainerView.isHidden = true
            self.subjectTitleView.isHidden = true
            self.subjectRequiredView.isHidden = true
            self.subjectInputView.isHidden = true
            self.messageTitleView.isHidden = true
            self.messageRequiredView.isHidden = true
            self.messageInputView.isHidden = true
            self.catergoryDropDownView.isHidden = true
            self.continueButton.isHidden = true
            self.successMessageView.isHidden = false
            self.successIconView.isHidden = false
        }
    }

    func addAutoLayoutContraints() {
        descriptionContentView.translatesAutoresizingMaskIntoConstraints = false
        categoryContentView.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        categoryView.translatesAutoresizingMaskIntoConstraints = false
        catergoryDropDownView.translatesAutoresizingMaskIntoConstraints = false
        divider1.translatesAutoresizingMaskIntoConstraints = false
        yourEmailView.translatesAutoresizingMaskIntoConstraints = false
        emailRequiredView.translatesAutoresizingMaskIntoConstraints = false
        emailInputView.translatesAutoresizingMaskIntoConstraints = false
        emailExplainerView.translatesAutoresizingMaskIntoConstraints = false
        subjectTitleView.translatesAutoresizingMaskIntoConstraints = false
        subjectRequiredView.translatesAutoresizingMaskIntoConstraints = false
        subjectInputView.translatesAutoresizingMaskIntoConstraints = false
        messageTitleView.translatesAutoresizingMaskIntoConstraints = false
        messageRequiredView.translatesAutoresizingMaskIntoConstraints = false
        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        successIconView.translatesAutoresizingMaskIntoConstraints = false
        successMessageView.translatesAutoresizingMaskIntoConstraints = false

        descriptionView.fillSuperview(padding: UIEdgeInsets(inset: 16))

        let descriptionViewConstraints = [
            descriptionContentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            descriptionContentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            descriptionContentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16)
        ]
        categoryContentView.anchor(top: categoryView.topAnchor,
                                   left: view.leftAnchor,
                                   right: view.rightAnchor,
                                   paddingTop: -16,
                                   paddingLeft: 16,
                                   paddingRight: 16,
                                   height: 48)

        let categoryViewConstraints = [
            categoryView.topAnchor.constraint(equalTo: descriptionContentView.bottomAnchor, constant: 38),
            categoryView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 32)
        ]
        let categoryDropDownViewConstraints = [
            catergoryDropDownView.topAnchor.constraint(equalTo: descriptionContentView.bottomAnchor, constant: 38),
            catergoryDropDownView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32),
            catergoryDropDownView.widthAnchor.constraint(equalToConstant: 60),
            catergoryDropDownView.heightAnchor.constraint(equalToConstant: 20)
        ]
        let yourEmailConstraints = [
            yourEmailView.topAnchor.constraint(equalTo: categoryContentView.bottomAnchor, constant: 24),
            yourEmailView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 32)
        ]
        let emailRequiredViewConstraints = [
            emailRequiredView.topAnchor.constraint(equalTo: categoryContentView.bottomAnchor, constant: 24),
            emailRequiredView.leftAnchor.constraint(equalTo: yourEmailView.rightAnchor, constant: 4)
        ]
        let emailInputViewConstraints = [
            emailInputView.topAnchor.constraint(equalTo: yourEmailView.bottomAnchor, constant: 8),
            emailInputView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            emailInputView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            emailInputView.heightAnchor.constraint(equalToConstant: 48)
        ]
        let emailExplainerViewConstraints = [
            emailExplainerView.topAnchor.constraint(equalTo: emailInputView.bottomAnchor, constant: 10),
            emailExplainerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 32),
            emailExplainerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 32)
        ]
        let subjectTitleViewConstraints = [
            subjectTitleView.topAnchor.constraint(equalTo: emailExplainerView.bottomAnchor, constant: 24),
            subjectTitleView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 32)
        ]
        let subjectRequiredViewConstraints = [
            subjectRequiredView.topAnchor.constraint(equalTo: subjectTitleView.topAnchor, constant: 0),
            subjectRequiredView.leftAnchor.constraint(equalTo: subjectTitleView.rightAnchor, constant: 4)
        ]
        let subjectInputViewConstraints = [
            subjectInputView.topAnchor.constraint(equalTo: subjectRequiredView.bottomAnchor, constant: 8),
            subjectInputView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            subjectInputView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            subjectInputView.heightAnchor.constraint(equalToConstant: 48)
        ]
        let messageTitleViewContraints = [
            messageTitleView.topAnchor.constraint(equalTo: subjectInputView.bottomAnchor, constant: 24),
            messageTitleView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 32)
        ]
        let messageRequiredViewContraints = [
            messageRequiredView.topAnchor.constraint(equalTo: messageTitleView.topAnchor, constant: 0),
            messageRequiredView.leftAnchor.constraint(equalTo: messageTitleView.rightAnchor, constant: 4)
        ]
        let messageInputViewContraints = [
            messageInputView.topAnchor.constraint(equalTo: messageTitleView.bottomAnchor, constant: 8),
            messageInputView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16),
            messageInputView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            messageInputView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16)
        ]
        let continueButtonViewContraints = [
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            continueButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            continueButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            continueButton.heightAnchor.constraint(equalToConstant: 48)
        ]
        let loadingViewContraints = [
            loadingView.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            loadingView.heightAnchor.constraint(equalToConstant: 48)
        ]
        let successIconViewConstraints = [
            successIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            successIconView.heightAnchor.constraint(equalToConstant: 48),
            successIconView.widthAnchor.constraint(equalToConstant: 48)
        ]
        let successMessageViewConstraints = [
            successMessageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 75),
            successMessageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -75),
            successMessageView.topAnchor.constraint(equalTo: successIconView.bottomAnchor, constant: 16)
        ]
        NSLayoutConstraint.activate(descriptionViewConstraints)
        NSLayoutConstraint.activate(categoryViewConstraints)
        NSLayoutConstraint.activate(categoryDropDownViewConstraints)
        NSLayoutConstraint.activate(yourEmailConstraints)
        NSLayoutConstraint.activate(emailRequiredViewConstraints)
        NSLayoutConstraint.activate(emailInputViewConstraints)
        NSLayoutConstraint.activate(emailExplainerViewConstraints)
        NSLayoutConstraint.activate(subjectTitleViewConstraints)
        NSLayoutConstraint.activate(subjectRequiredViewConstraints)
        NSLayoutConstraint.activate(subjectInputViewConstraints)
        NSLayoutConstraint.activate(messageTitleViewContraints)
        NSLayoutConstraint.activate(messageRequiredViewContraints)
        NSLayoutConstraint.activate(messageInputViewContraints)
        NSLayoutConstraint.activate(continueButtonViewContraints)
        NSLayoutConstraint.activate(loadingViewContraints)
        NSLayoutConstraint.activate(successIconViewConstraints)
        NSLayoutConstraint.activate(successMessageViewConstraints)
    }

    func setupUI(isDark: Bool) {
        setupViews(isDark: isDark)
        descriptionContentView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark).cgColor
        descriptionContentView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark).cgColor
        if !isDark {
            descriptionView.textColor = UIColor.midnight
            categoryView.textColor = UIColor.midnight
            divider1.backgroundColor = UIColor.midnight
            yourEmailView.textColor = UIColor.midnight
            emailRequiredView.textColor = UIColor.midnight
            emailInputView.backgroundColor = UIColor.midnightWithOpacity(opacity: 0.10)
            emailInputView.textColor = UIColor.midnight
            emailExplainerView.textColor = UIColor.midnight
            subjectTitleView.textColor = UIColor.midnight
            subjectRequiredView.textColor = UIColor.midnight
            subjectInputView.backgroundColor = UIColor.midnightWithOpacity(opacity: 0.10)
            subjectInputView.textColor = UIColor.midnight
            messageTitleView.textColor = UIColor.midnight
            messageRequiredView.textColor = UIColor.midnight
            messageInputView.backgroundColor = UIColor.midnightWithOpacity(opacity: 0.10)
            messageInputView.textColor = UIColor.midnight
            successMessageView.textColor = UIColor.midnight
        } else {
            descriptionView.textColor = UIColor.white
            categoryView.textColor = UIColor.white
            divider1.backgroundColor = UIColor.white
            yourEmailView.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
            emailRequiredView.textColor = UIColor.white
            emailInputView.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.10)
            emailInputView.textColor = UIColor.white
            emailExplainerView.textColor = UIColor.white
            subjectTitleView.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
            subjectRequiredView.textColor = UIColor.white
            subjectInputView.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.10)
            subjectInputView.textColor = UIColor.white
            messageTitleView.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
            messageRequiredView.textColor = UIColor.white
            messageInputView.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.10)
            messageInputView.textColor = UIColor.white
            successMessageView.textColor = UIColor.white
        }
    }

    func enableContinueButton() {
        continueButtonEnabledSubject.onNext(true)
        continueButton.isEnabled = true
        continueButton.setTitleColor(UIColor.midnight, for: .normal)
    }

    func disableContinueButton() {
        continueButtonEnabledSubject.onNext(false)
        continueButton.isEnabled = false
        continueButton.setTitleColor(UIColor.midnightWithOpacity(opacity: 0.5), for: .normal)
    }

    @objc func fieldsValueChanged() {
        let email = emailInputView.text!
        let subject = subjectInputView.text!
        let message = messageInputView.text!
        if !email.isValidEmail() {
            emailRequiredView.layer.opacity = 0.5
            disableContinueButton()
            return
        }
        if subject.count < 3 {
            subjectRequiredView.layer.opacity = 0.5
            disableContinueButton()
            return
        }
        if message.count < 3 {
            messageRequiredView.layer.opacity = 0.5
            disableContinueButton()
            return
        }
        enableContinueButton()
    }

    func clearFieldsError() {
        disableContinueButton()
        emailRequiredView.layer.opacity = 0.5
        subjectRequiredView.layer.opacity = 0.5
        messageRequiredView.layer.opacity = 0.5
    }

    func textViewDidChange(_: UITextView) {
        fieldsValueChanged()
    }

    func textViewDidEndEditing(_: UITextView) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }

    func textFieldDidEndEditing(_: UITextField) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
}

extension SubmitTicketViewController: DropdownButtonDelegate {
    func dropdownButtonTapped(_ sender: DropdownButton) {
        tappedOnScreen()
        currentDropdownView = Dropdown(attachedView: sender)
        guard let dropdown = currentDropdownView else { return }
        dropdown.relatedIndex = 0
        dropdown.maxHeight = 180
        dropdown.dropDownDelegate = self
        switch sender {
        case catergoryDropDownView:
            dropdown.options = TextsAsset.SubmitTicket.categories
        default:
            return
        }
        sender.dropdown = dropdown
        viewDismiss.addTapGesture(target: self, action: #selector(dismissDropdown))
        view.addSubview(viewDismiss)
        viewDismiss.fillSuperview()
        view.addSubview(dropdown)
    }
}
