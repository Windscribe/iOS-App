//
//  WSRefreshControl.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-07.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class WSRefreshControl: UIRefreshControl {
    var disposeBag = DisposeBag()

    var backView: RefreshControlViewBack! {
        didSet {
            self.subviews[0].addSubview(backView)
        }
    }

    init(isDarkMode: BehaviorSubject<Bool>) {
        super.init()
        self.setText(TextsAsset.refreshLatency)
        self.layer.opacity = 0.5
        self.tintColor = UIColor.midnight
        self.backgroundColor = UIColor.clear
        bindViews(isDarkMode: isDarkMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String, size: CGFloat = 12) {
        let color = tintColor ?? UIColor.white
        let myAttribute = [NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.font: UIFont.bold(size: size)]
        let myAttrString = NSAttributedString(string: text, attributes: myAttribute)
        self.attributedTitle = myAttrString
    }

    func resetText() {
        setText(TextsAsset.refreshLatency)
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: {
            self.updateDarkMode(isDarkMode: $0)
        }).disposed(by: self.disposeBag)
    }

    private func updateDarkMode(isDarkMode: Bool) {
        guard backView != nil else {
            disposeBag = DisposeBag()
            return
        }
        tintColor = isDarkMode ? UIColor.white : UIColor.midnight
        backgroundColor = isDarkMode ? UIColor.darkBlack : UIColor.seperatorWhite
        backView.label.backgroundColor = isDarkMode ? UIColor.darkBlack : UIColor.seperatorWhite
        backView.label.textColor = isDarkMode ? UIColor.white : UIColor.midnight
        setText(self.attributedTitle?.string ?? TextsAsset.refreshLatency)
    }
}
