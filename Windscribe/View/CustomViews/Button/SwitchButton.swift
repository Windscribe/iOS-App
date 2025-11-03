//
//  SwitchButton.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Combine
import RxSwift
import UIKit

class SwitchButton: UIButton {
    var isDarkMode: CurrentValueSubject<Bool, Never>
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */
    var status: Bool = false {
        didSet {
            update()
        }
    }

    var onImage = UIImage(named: ImagesAsset.SwitchButton.on)
    var offImage = UIImage(named: ImagesAsset.SwitchButton.offBlack)

    init(isDarkMode: CurrentValueSubject<Bool, Never>) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setStatus(false)
        bindViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
        setImage(status ? onImage : offImage, for: .normal)
    }

    private func bindViews() {
        isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.updateTheme(isDark: isDark)
            }
            .store(in: &cancellables)
    }
}
