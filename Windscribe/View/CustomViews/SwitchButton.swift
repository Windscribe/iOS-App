//
//  SwitchButton.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class SwitchButton: UIButton {
    var isDarkMode: BehaviorSubject<Bool>
    let disposeBag = DisposeBag()
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var status: Bool = false {
        didSet {
            self.update()
        }
    }

    var onImage = UIImage(named: ImagesAsset.SwitchButton.on)
    var offImage = UIImage(named: ImagesAsset.SwitchButton.offBlack)

    init(isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setStatus(false)
        bindViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update() {
        UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: {
            self.status ? self.setImage(self.onImage, for: .normal) : self.setImage(self.offImage, for: .normal)
        }, completion: nil)
    }

    func toggle() {
        setStatus(!status)
    }

    func setStatus(_ status: Bool) {
        self.status = status
    }

    override func updateTheme(isDark: Bool) {
        offImage = ThemeUtils.switchOffImage(isDarkMode: isDark)
        self.setImage(status ? onImage : offImage, for: .normal)
    }

    private func bindViews() {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: {
            self.updateTheme(isDark: $0)
        }).disposed(by: self.disposeBag)
    }
}
