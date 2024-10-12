//
//  SignUpViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-10.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import RxSwift
import RxGesture

class SignUpViewController: WSNavigationViewController {
    // MARK: - UI properties
    var scrollView: UIScrollView!
    var headingLabel: UILabel!
    var loadingView: UIActivityIndicatorView!
    var continueButtonBottomConstraint: NSLayoutConstraint!
    // MARK: - username
    lazy var usernameLabel: UILabel = {
        let usernameLabel = UILabel()
        usernameLabel.font = UIFont.bold(size: 16)
        usernameLabel.textAlignment = .left
        return usernameLabel
    }()

    lazy var usernameTextfield: LoginTextField = {
        let usernameTextfield = LoginTextField(isDarkMode: viewModel.isDarkMode)
        usernameTextfield.makeCorner(24)
        return usernameTextfield
    }()

    lazy var usernameInfoLabel: UILabel = {
        let usernameInfoLabel = UILabel()
        usernameInfoLabel.font = UIFont.text(size: 12)
        usernameInfoLabel.adjustsFontSizeToFitWidth = true
        usernameInfoLabel.textAlignment = .left
        usernameInfoLabel.textColor = UIColor.failRed
        usernameInfoLabel.layer.opacity = 0.5
        return usernameInfoLabel
    }()

    lazy var usernameInfoIconImageView: UIImageView = {
        let usernameInfoIconImageView = UIImageView()
        usernameInfoIconImageView.isHidden = true
        usernameInfoIconImageView.image = UIImage(named: ImagesAsset.failExIcon)
        return usernameInfoIconImageView
    }()

    lazy var userNameView: UIView = {
        let vw = UIView()
        vw.addSubview(usernameLabel)
        vw.addSubview(usernameTextfield)
        vw.addSubview(usernameInfoLabel)
        vw.addSubview(usernameInfoIconImageView)
        usernameLabel.anchor(top: vw.topAnchor,
                             left: vw.leftAnchor,
                             paddingTop: 8,
                             paddingLeft: 16)
        usernameTextfield.anchor(top: usernameLabel.bottomAnchor,
                                 left: vw.leftAnchor,
                                 bottom: vw.bottomAnchor,
                                 right: vw.rightAnchor,
                                 paddingTop: 8,
                                 paddingBottom: 24,
                                 height: 48)
        usernameInfoIconImageView.anchor(top: vw.topAnchor,
                                         right: vw.rightAnchor,
                                         paddingTop: 8,
                                         paddingRight: 0,
                                         width: 16 ,height: 16)
        usernameInfoLabel.anchor(top: usernameTextfield.bottomAnchor,
                                 left: vw.leftAnchor,
                                 right: vw.rightAnchor,
                                 paddingTop: 8,
                                 paddingLeft: 16,
                                 paddingRight: 8)
        return vw
    }()

    // MARK: - password view
    lazy var passwordLabel: UILabel = {
        let passwordLabel = UILabel()
        passwordLabel.font = UIFont.bold(size: 16)
        passwordLabel.textAlignment = .left
        return passwordLabel
    }()

    lazy var passwordTextfield: PasswordTextField = {
        let passwordTextfield = PasswordTextField(isDarkMode: viewModel.isDarkMode)
        passwordTextfield.makeCorner(24)
        return passwordTextfield
    }()

    lazy var passwordInfoLabel: UILabel = {
        let passwordInfoLabel = UILabel()
        passwordInfoLabel.font = UIFont.text(size: 12)
        passwordInfoLabel.adjustsFontSizeToFitWidth = true
        passwordInfoLabel.textAlignment = .left
        passwordInfoLabel.textColor = UIColor.failRed
        passwordInfoLabel.layer.opacity = 0.5
        return passwordInfoLabel
    }()

    lazy var passwordInfoIconImageView: UIImageView = {
        let passwordInfoIconImageView = UIImageView()
        passwordInfoIconImageView.isHidden = true
        passwordInfoIconImageView.image = UIImage(named: ImagesAsset.failExIcon)
        return passwordInfoIconImageView
    }()

    lazy var passwordView: UIView = {
        let vw = UIView()
        vw.addSubview(passwordLabel)
        vw.addSubview(passwordTextfield)
        vw.addSubview(passwordInfoLabel)
        vw.addSubview(passwordInfoIconImageView)
        passwordLabel.anchor(top: vw.topAnchor,
                             left: vw.leftAnchor,
                             paddingTop: 8,
                             paddingLeft: 16)
        passwordTextfield.anchor(top: passwordLabel.bottomAnchor,
                                 left: vw.leftAnchor,
                                 bottom: vw.bottomAnchor,
                                 right: vw.rightAnchor,
                                 paddingTop: 8,
                                 paddingBottom: 24,
                                 height: 48)
        passwordInfoIconImageView.anchor(top: vw.topAnchor,
                                         right: vw.rightAnchor,
                                         paddingTop: 8,
                                         paddingRight: 0,
                                         width: 16 ,height: 16)
        passwordInfoLabel.anchor(top: passwordTextfield.bottomAnchor,
                                 left: vw.leftAnchor,
                                 right: vw.rightAnchor,
                                 paddingTop: 8,
                                 paddingLeft: 16,
                                 paddingRight: 8)
        return vw
    }()

    // MARK: - Email view
    lazy var emailLabel: UILabel = {
        let emailLabel = UILabel()
        emailLabel.font = UIFont.bold(size: 16)
        emailLabel.textAlignment = .left
        return emailLabel
    }()

    lazy var emailOptionalLabel: UILabel = {
        let emailOptionalLabel = UILabel()
        emailOptionalLabel.font = UIFont.bold(size: 16)
        emailOptionalLabel.textAlignment = .left
        return emailOptionalLabel
    }()

    lazy var emailTextfield: LoginTextField = {
        let emailTextfield = LoginTextField(isDarkMode: viewModel.isDarkMode)
        emailTextfield.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 100)
        emailTextfield.makeCorner(24)
        emailTextfield.autocorrectionType = .yes
        emailTextfield.textContentType = .emailAddress
        emailTextfield.spellCheckingType = .no
        return emailTextfield
    }()

    lazy var emailInfoLabel: UILabel = {
        let emailInfoLabel = UILabel()
        emailInfoLabel.font = UIFont.text(size: 12)
        emailInfoLabel.textAlignment = .right
        emailInfoLabel.layer.opacity = 0.5
        return emailInfoLabel
    }()

    lazy var emailInfoIconImageView: UIImageView = {
        let emailInfoIconImageView = UIImageView()
        emailInfoIconImageView.isHidden = true
        emailInfoIconImageView.image = UIImage(named: ImagesAsset.failExIcon)
        return emailInfoIconImageView
    }()

    lazy var infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.adjustsFontSizeToFitWidth = true
        infoLabel.font = UIFont.text(size: 12)
        infoLabel.textAlignment = .left
        infoLabel.layer.opacity = 0.5
        return infoLabel
    }()

    lazy var emailView: UIView = {
        let vw = UIView()
        vw.addSubview(emailLabel)
        vw.addSubview(emailTextfield)
        vw.addSubview(emailInfoLabel)
        vw.addSubview(emailInfoIconImageView)
        vw.addSubview(emailOptionalLabel)
        vw.addSubview(infoLabel)
        emailLabel.anchor(top: vw.topAnchor,
                          left: vw.leftAnchor,
                          paddingTop: 8,
                          paddingLeft: 16)
        emailOptionalLabel.makeCenterYAnchor(with: emailLabel)
        emailOptionalLabel.anchor(left: emailLabel.rightAnchor,
                                  paddingLeft: 5)
        emailTextfield.anchor(top: emailLabel.bottomAnchor,
                              left: vw.leftAnchor,
                              bottom: vw.bottomAnchor,
                              right: vw.rightAnchor,
                              paddingTop: 8,
                              paddingBottom: 24,
                              height: 48)
        emailInfoIconImageView.anchor(top: vw.topAnchor,
                                      right: vw.rightAnchor,
                                      paddingTop: 8,
                                      paddingRight: 0,
                                      width: 16 ,height: 16)
        emailInfoLabel.anchor(right: emailTextfield.rightAnchor,
                              paddingRight: 16)
        emailInfoLabel.makeCenterYAnchor(with: emailTextfield)
        infoLabel.anchor(top: emailTextfield.bottomAnchor,
                         left: vw.leftAnchor,
                         right: vw.rightAnchor,
                         paddingTop: 8,
                         paddingLeft: 16,
                         paddingRight: 16)
        return vw
    }()

    // MARK: - Voucher view
    lazy var voucherLabel: UILabel = {
        let voucherLabel = UILabel()
        voucherLabel.font = UIFont.bold(size: 16)
        voucherLabel.textAlignment = .left
        return voucherLabel
    }()

    lazy var voucherOptionalLabel: UILabel = {
        let voucherOptionalLabel = UILabel()
        voucherOptionalLabel.font = UIFont.bold(size: 16)
        voucherOptionalLabel.textAlignment = .left
        return voucherOptionalLabel
    }()

    lazy var voucherTextfield: LoginTextField = {
        let voucherTextfield = LoginTextField(isDarkMode: viewModel.isDarkMode)
        voucherTextfield.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 100)
        voucherTextfield.makeCorner(24)
        voucherTextfield.autocorrectionType = .yes
        voucherTextfield.textContentType = .emailAddress
        voucherTextfield.spellCheckingType = .no
        return voucherTextfield
    }()

    lazy var voucherView: UIView = {
        let vw = UIView()
        vw.addSubview(voucherLabel)
        vw.addSubview(voucherTextfield)
        vw.addSubview(voucherOptionalLabel)
        voucherLabel.anchor(top: vw.topAnchor,
                          left: vw.leftAnchor,
                          paddingTop: 30,
                          paddingLeft: 16)
        voucherOptionalLabel.makeCenterYAnchor(with: voucherLabel)
        voucherOptionalLabel.anchor(left: voucherLabel.rightAnchor,
                                  paddingLeft: 5)
        voucherTextfield.anchor(top: voucherLabel.bottomAnchor,
                              left: vw.leftAnchor,
                              bottom: vw.bottomAnchor,
                              right: vw.rightAnchor,
                              paddingTop: 8,
                              paddingBottom: 24,
                              height: 48)
        return vw
    }()

    // MARK: - Referred section
    lazy var referralTitle: UILabel = {
        let referralTitle = UILabel()
        referralTitle.font = UIFont.bold(size: 16)
        referralTitle.textAlignment = .left
        referralTitle.isUserInteractionEnabled = true
        return referralTitle
    }()

    lazy var referralUsernameTextfield: LoginTextField = {
        let referralUsernameTextfield = LoginTextField(isDarkMode: viewModel.isDarkMode)
        referralUsernameTextfield.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 100)
        referralUsernameTextfield.makeCorner(24)
        referralUsernameTextfield.anchor(height: 48)
        referralUsernameTextfield.isHidden = true
        return referralUsernameTextfield
    }()

    lazy var referralArrowIcon: UIImageView = {
        let referralArrowIcon = UIImageView()
        referralArrowIcon.isHidden = false
        referralArrowIcon.contentMode = .scaleAspectFit
        referralArrowIcon.image = UIImage(named: ImagesAsset.downArrow)
        referralArrowIcon.alpha = 0.5
        return referralArrowIcon
    }()

    lazy var referral1View: CheckView = {
        let vw = CheckView(content: TextsAsset.youWillBothGetTenGb, isDarkMode: viewModel.isDarkMode)
        vw.isHidden = true
        return vw
    }()

    lazy var referral2View: CheckView = {
        let vw = CheckView(content: TextsAsset.ifYouGoPro, isDarkMode: viewModel.isDarkMode)
        vw.isHidden = true
        return vw
    }()

    lazy var referralInfoLabel: UILabel = {
        let lbl = UILabel()
        lbl.adjustsFontSizeToFitWidth = true
        lbl.font = UIFont.text(size: 12)
        lbl.textAlignment = .left
        lbl.textColor = UIColor.white
        lbl.layer.opacity = 0.5
        lbl.numberOfLines = 0
        return lbl
    }()

    lazy var referralTitleWithIcon: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            referralTitle,
            referralArrowIcon,
            UIView()
        ])
        stack.isUserInteractionEnabled = true
        stack.spacing = 8
        stack.axis = .horizontal
        return stack
    }()

    lazy var referredIntroView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            referralTitleWithIcon,
            referral1View,
            referral2View
        ])
        stack.spacing = 4
        stack.axis = .vertical
        stack.setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 0))
        return stack
    }()

    lazy var referralInfoView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            referralInfoLabel
        ])
        stack.isHidden = true
        stack.axis = .vertical
        stack.setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 0))
        return stack
    }()

    lazy var viewReferral: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            referredIntroView,
            referralUsernameTextfield,
            referralInfoView
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(16, after: referralTitle)
        stack.setPadding(UIEdgeInsets(horizontalInset: 0, verticalInset: 24))
        return stack
    }()
    // MARK: - Action button
    lazy var continueButton: UIButton = {
        let continueButton = UIButton(type: .system)
        continueButton.anchor(height: 48)
        continueButton.layer.cornerRadius = 24
        continueButton.clipsToBounds = true
        continueButton.setTitleColor(UIColor.midnight, for: .normal)
        continueButton.backgroundColor = UIColor.seaGreen
        return continueButton
    }()

    lazy var setupLaterButton: UIButton = {
        let setupLaterButton = UIButton(type: .system)
        setupLaterButton.isHidden = true
        setupLaterButton.setTitleColor(UIColor.white, for: .normal)
        setupLaterButton.titleLabel?.font = UIFont.bold(size: 16)
        setupLaterButton.layer.opacity = 0.5
        return setupLaterButton
    }()
    // MARK: - State properties
    var viewModel: SignUpViewModel!, router: SignupRouter!, popupRouter: PopupRouter!, logger: FileLogger!
    var claimGhostAccount = false
    // MARK: - UI Events
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Sign Up View")
        setupViews()
        bindViews()
    }

    override func setupLocalized() {
        setupLaterButton.setTitle(TextsAsset.setupLater, for: .normal)
        continueButton.setTitle(TextsAsset.continue, for: .normal)
        infoLabel.text = TextsAsset.emailInfoLabel
        emailInfoLabel.text = "\(TextsAsset.get10GbAMonth)"
        emailOptionalLabel.text = "(\(TextsAsset.optional))"
        emailLabel.text = TextsAsset.yourEmail
        passwordLabel.text = TextsAsset.choosePassword
        usernameLabel.text = TextsAsset.chooseUsername
        referralTitle.text = TextsAsset.referredBySomeone
        referralInfoLabel.text = TextsAsset.mustConfirmEmail
        voucherLabel.text = TextsAsset.voucherCode
        voucherOptionalLabel.text = "(\(TextsAsset.optional))"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 150
    }

    @objc func tappedOnScreen() {
        usernameTextfield.resignFirstResponder()
        passwordTextfield.resignFirstResponder()
    }

    // MARK: - Setup and Bind views
    private func setupViews() {
        self.addPromptBackgroundView()
        self.titleLabel.text = TextsAsset.createAccount
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedOnScreen))
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
        passwordTextfield.delegate = self
        setupFillLayoutView()
        layoutView.stackView.addArrangedSubviews([
            userNameView,
            passwordView,
            emailView,
            voucherView,
            viewReferral
        ])
        layoutView.stackView.setPadding(UIEdgeInsets(top: 24, left: 16, bottom: 0, right: 16))
        layoutView.bottomStackView.addArrangedSubviews([
            continueButton,
            setupLaterButton
        ])
        layoutView.bottomStackView.spacing = 24
        layoutView.bottomStackView.setPadding(UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16))
    }

    private func bindViews() {
        if claimGhostAccount {
            setClaimAccountView()
        }
        viewModel.showLoadingView.bind { [self] show in
            if show {
                showLoading()
            } else {
                endLoading()
            }
        }.disposed(by: disposeBag)
        viewModel.textfieldStatus.bind { [self] show in
            self.usernameTextfield.isEnabled = show
            self.passwordTextfield.isEnabled = show
            self.emailTextfield.isEnabled = show
            self.continueButton.setTitle(TextsAsset.continue, for: .normal)
        }.disposed(by: disposeBag)
        referralTitle.rx.tapGesture().bind { [self] _ in
            viewModel.referralViewTapped()
        }.disposed(by: disposeBag)
        referralArrowIcon.rx.tapGesture().bind { [self] _ in
            viewModel.referralViewTapped()
        }.disposed(by: disposeBag)
        continueButton.rx.tap.bind { [self] in
            viewModel.continueButtonTapped(userName: usernameTextfield.text, password: passwordTextfield.text, email: emailTextfield.text, referrelUsername: referralUsernameTextfield.text, ignoreEmailCheck: false, claimAccount: claimGhostAccount, voucherCode: voucherTextfield.text)
        }.disposed(by: disposeBag)
        setupLaterButton.rx.tap.bind { [self] in
            viewModel.setupLaterButtonTapped()
        }.disposed(by: disposeBag)
        viewModel.routeTo.bind { [self] route in
            handleRoute(route: route)
        }.disposed(by: disposeBag)

        Observable.combineLatest(usernameTextfield.rx.text.asObservable(),
                                 viewModel.isDarkMode.asObservable()).bind { (_, isDarkMode) in
            self.signUpTextFieldValueChanged(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)

        Observable.combineLatest(passwordTextfield.rx.text.asObservable(),
                                 viewModel.isDarkMode.asObservable()).bind { (_, isDarkMode) in
            self.signUpTextFieldValueChanged(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)

        Observable.combineLatest(emailTextfield.rx.text.asObservable(),
                                 viewModel.referralViewStatus.asObservable(),
                                 viewModel.isDarkMode.asObservable()).bind { (_, expanded, isDarkMode) in
            self.checkReferralEmail(expanded: expanded, isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)

        Observable.combineLatest(viewModel.failedState.asObservable(), viewModel.isDarkMode.asObservable()).bind { (state, isDarkMode) in
            self.setFailureState(state: state, isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)

        Observable.combineLatest(viewModel.referralViewStatus.asObservable(), viewModel.isDarkMode.asObservable()).bind { (show, isDarkMode) in
            self.setReferralViewVisibility(show: show, isDarkMode: isDarkMode)
            self.checkReferralEmail(expanded: show, isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)

        viewModel.isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: {
            self.usernameLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.passwordLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.emailLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.emailOptionalLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.emailInfoLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.infoLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.referralTitle.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.voucherLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.voucherOptionalLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)

            self.referralArrowIcon.updateTheme( isDark: $0)
            super.setupViews(isDark: $0)
        }).disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .bind { [weak self] _ in
                self?.viewModel.keyBoardWillShow()
            }.disposed(by: disposeBag)
    }

    // MARK: - Helper
    private func clearError(isDarkMode: Bool) {
        self.usernameTextfield.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        self.usernameInfoIconImageView.isHidden = true
        self.usernameInfoLabel.isHidden = true
        self.passwordTextfield.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        self.passwordInfoIconImageView.isHidden = true
        self.passwordInfoLabel.isHidden = true
        self.emailTextfield.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        self.emailInfoIconImageView.isHidden = true
        self.infoLabel.text = TextsAsset.emailInfoLabel
        self.infoLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
    }

    private func setFailureState(state: SignUpErrorState, isDarkMode: Bool) {
        switch state {
        case .username(let error):
            self.usernameTextfield.textColor = UIColor.failRed
            self.usernameInfoIconImageView.isHidden = false
            self.usernameInfoLabel.text = error
            self.usernameInfoLabel.isHidden = false
        case .password(let error):
            self.passwordTextfield.textColor = UIColor.failRed
            self.passwordInfoIconImageView.isHidden = false
            self.passwordInfoLabel.text = error
            self.passwordInfoLabel.isHidden = false
        case .email(let error):
            self.emailInfoIconImageView.isHidden = false
            self.infoLabel.text = error
            self.infoLabel.textColor = UIColor.failRed
        case .api(let error):
            self.infoLabel.text = error
            self.infoLabel.textColor = UIColor.failRed
        case .network(let error):
            self.infoLabel.text = error
            self.infoLabel.textColor = UIColor.failRed
        case .none:
            clearError(isDarkMode: isDarkMode)
        }
    }

    private func checkReferralEmail(expanded: Bool, isDarkMode: Bool) {
        if expanded {
            if emailTextfield.text?.isEmpty ?? true {
                referralUsernameTextfield.isUserInteractionEnabled = false
                referralUsernameTextfield.attributedPlaceholder = NSAttributedString(
                    string: TextsAsset.pleaseEnterEmailFirst,
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.failRed]
                )
                emailInfoIconImageView.isHidden = false
            } else {
                referralUsernameTextfield.attributedPlaceholder = NSAttributedString(
                    string: TextsAsset.referringUsername,
                    attributes: [NSAttributedString.Key.foregroundColor: ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)]
                )
                referralUsernameTextfield.isUserInteractionEnabled = true
                if (emailTextfield.text ?? "").isValidEmail() {
                    emailInfoIconImageView.isHidden = true
                } else {
                    emailInfoIconImageView.isHidden = false
                }
            }
        } else {
            emailInfoIconImageView.isHidden = true
        }
    }

    private func setReferralViewVisibility(show: Bool, isDarkMode: Bool) {
        referralUsernameTextfield.isHidden = !show
        referralInfoView.isHidden = !show
        referral1View.isHidden = !show
        referral2View.isHidden = !show
        if show {
            referralTitle.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            referralArrowIcon.image = UIImage(named: ImagesAsset.upArrow)
            referralArrowIcon.alpha = 1
            referralArrowIcon.updateTheme(isDark: isDarkMode)
        } else {
            referralTitle.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
            referralArrowIcon.image = UIImage(named: ImagesAsset.downArrow)
            referralArrowIcon.alpha = 0.5
            referralArrowIcon.updateTheme(isDark: isDarkMode)
        }
    }

    private func showNoEmailPrompt() {
        self.showPromptBackgroundView()
        let isPro = (try? viewModel.isPremiumUser.value()) ?? false
        popupRouter.routeTo(to: .infoPrompt(title: isPro ? TextsAsset.NoEmailPrompt.titlePro : TextsAsset.NoEmailPrompt.title,
                                            actionValue: TextsAsset.NoEmailPrompt.action,
                                            justDismissOnAction: false,
                                            delegate: self),
                            from: self)
    }

    private func showSetupLaterPrompt() {
        self.view.endEditing(true)
        self.showPromptBackgroundView()
        popupRouter.routeTo(to: .infoPrompt(title: TextsAsset.SetupLaterPrompt.title,
                                            actionValue: TextsAsset.SetupLaterPrompt.action,
                                            justDismissOnAction: claimGhostAccount,
                                            delegate: self),
                            from: self)
    }

    private func setClaimAccountView() {
        self.titleLabel.text = TextsAsset.accountSetupTitle
        self.infoLabel.text = TextsAsset.accountSetupMessage
        self.setupLaterButton.isHidden = false
        self.emailInfoLabel.isHidden = true
        self.viewReferral.isHidden = true
    }

    private func handleRoute(route: SignupRoutes) {
        logger.logD(self, "moving to \(route)")
        switch route {
        case .main:
            router.routeTo(to: RouteID.home, from: self)
        case .noEmail:
            showNoEmailPrompt()
        case .confirmEmail:
            let vc = ConfirmEmailViewController()
            vc.dismissDelegate = self
            present(vc, animated: true, completion: nil)
        case .setupLater:
            showSetupLaterPrompt()
        }
    }

    @objc func signUpTextFieldValueChanged(isDarkMode: Bool) {
        guard let usernameTextCount = usernameTextfield.text?.count, let passwordTextCount = passwordTextfield.text?.count else { return }
        if usernameTextCount > 2 && passwordTextCount > 2 {
            self.continueButton.backgroundColor = UIColor.seaGreen
            self.continueButton.setTitleColor(UIColor.midnight, for: .normal)
            self.continueButton.isEnabled = true
        } else {
            self.continueButton.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: isDarkMode)
            self.continueButton.setTitleColor(ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode), for: .normal)
            self.continueButton.isEnabled = false
        }
    }
}

// MARK: - Extensions

extension SignUpViewController: InfoPromptViewDelegate {
    func dismissWith(actionTaken: Bool, dismiss: Bool) {
        hidePromptBackgroundView()
        if dismiss {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        if actionTaken {
            viewModel.continueButtonTapped(userName: usernameTextfield.text, password: passwordTextfield.text, email: emailTextfield.text, referrelUsername: referralUsernameTextfield.text, ignoreEmailCheck: true, claimAccount: claimGhostAccount, voucherCode: voucherTextfield.text)
        }
    }
}

extension SignUpViewController: ConfirmEmailViewControllerDelegate {
    func dismissWith(action: ConfirmEmailAction) {
        router.dismissPopup(action: action, navigationVC: self.navigationController)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
