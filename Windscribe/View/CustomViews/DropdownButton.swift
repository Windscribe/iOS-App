//
//  DropdownButton.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-29.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

protocol DropdownButtonDelegate: AnyObject {
    func dropdownButtonTapped(_ sender: DropdownButton)
}

class DropdownButton: UIView {
    var isDarkMode: BehaviorSubject<Bool>
    let disposeBag = DisposeBag()

    var button: UIButton!
    var icon: UIButton!
    var dropdown: Dropdown?
    weak var delegate: DropdownButtonDelegate?

    init(isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        isUserInteractionEnabled = true

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(tapRecognizer)

        button = LargeTapAreaImageButton()
        button.isUserInteractionEnabled = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.text(size: 16)
        button.layer.opacity = 0.5
        addSubview(button)

        icon = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        icon.isUserInteractionEnabled = false
        icon.setImage(UIImage(named: ImagesAsset.dropDownIcon), for: .normal)
        addSubview(icon)

        button.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: button as Any,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: icon,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: -8),
            NSLayoutConstraint(item: button as Any,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: button as Any,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 20),
        ])

        addConstraints([
            NSLayoutConstraint(item: icon as Any,
                               attribute: .centerY,
                               relatedBy: .equal,
                               toItem: button,
                               attribute: .centerY,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: icon as Any,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: icon as Any,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 16),
            NSLayoutConstraint(item: icon as Any,
                               attribute: .width,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .width,
                               multiplier: 1.0,
                               constant: 16),
        ])
        bindViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ text: String?) {
        button.setTitle(text, for: .normal)
    }

    @objc func viewTapped() {
        delegate?.dropdownButtonTapped(self)
    }

    func remove() {
        dropdown?.removeWithAnimation()
    }

    private func bindViews() {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            if !$0 {
                self.button.setTitleColor(UIColor.midnight, for: .normal)
                self.icon.setImage(UIImage(named: ImagesAsset.dropDownIcon), for: .normal)
            } else {
                self.button.setTitleColor(UIColor.white, for: .normal)
                self.icon.setImage(UIImage(named: ImagesAsset.DarkMode.dropDownIcon), for: .normal)
            }
        }).disposed(by: disposeBag)
    }
}
