//
//  SubmitTicketViewController.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-24.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import IQKeyboardManagerSwift
import RxSwift
import Swinject
import UIKit

class SubmitTicketViewController: WSNavigationViewController {
    var descriptionContentView: UIView!
    var categoryContentView: UIView!
    var descriptionView,
        categoryView,
        yourEmailView,
        emailRequiredView,
        emailExplainerView,
        messageTitleView,
        messageRequiredView,
        subjectTitleView,
        subjectRequiredView,
        successMessageView: UILabel!
    var successIconView: UIImageView!
    var divider1: UIView!
    var catergoryDropDownView: DropdownButton!
    var emailInputView,
        subjectInputView: AuthenticationTextField!
    var messageInputView: UITextView!
    var continueButton: UIButton!
    var loadingView: UIActivityIndicatorView!

    var logger: FileLogger!, viewModel: SubmitTicketViewModel!
    lazy var continueButtonEnabledSubject: BehaviorSubject<Bool> = BehaviorSubject(value: self.continueButton.isEnabled)

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Submit ticket View")
        view.backgroundColor = UIColor.darkGray
        addViews()
        addAutoLayoutContraints()
        titleLabel.text = TextsAsset.SubmitTicket.submitTicket
        bindViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 150
    }

    func showAlertDialog(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.hideProgressView()
            self?.viewModel.alertManager.showSimpleAlert(viewController: self, title: title, message: message, buttonText: "Ok")
        }
    }

    @objc func continueSendTicketTapped() {
        guard let email = emailInputView.text else { return }
        let category = catergoryDropDownView.button.title(for: .normal)
        guard let categoryValue = TextsAsset.SubmitTicket.categoryValues[category!] else { return }
        guard let subject = subjectInputView.text else { return }
        guard let message = messageInputView.text else { return }

        showProgressView()
        DispatchQueue.main.async { [weak self] in
            self?.subjectInputView.text = ""
            self?.messageInputView.text = ""
            self?.emailInputView.text = ""
            self?.disableContinueButton()
        }

        viewModel.sendTicket(email: email, subject: subject, message: message, category: categoryValue).subscribe(onSuccess: { _ in
            self.showSuccessView()
        }, onFailure: { error in
            if error.localizedDescription != "" {
                self.showAlertDialog(title: "Error", message: error.localizedDescription)
            } else {
                self.showAlertDialog(title: "Error", message: TextsAsset.SubmitTicket.failedToSendTicket)
            }
        })
        .disposed(by: disposeBag)
    }

    @objc func tappedOnScreen() {
        if catergoryDropDownView != nil {
            catergoryDropDownView.remove()
        }
    }
}

extension SubmitTicketViewController: DropdownDelegate {
    func optionSelected(dropdown: Dropdown, option: String, relatedIndex _: Int) {
        dismissDropdown()
        switch dropdown {
        case catergoryDropDownView.dropdown:
            catergoryDropDownView.setTitle(option)
        default:
            return
        }
    }
}
