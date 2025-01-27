//
//  LoadingSplashView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-26.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class LoadingSplashView: UIView {
    var logoView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black

        logoView = UIImageView(frame: CGRect(x: self.frame.width / 2 - 40, y: self.frame.height / 2 - 40, width: 80, height: 80))
        let logoImageData = try? Data(contentsOf: Bundle.main.url(forResource: "ws-rotating-logo", withExtension: "gif")!)
        let logoGifImage = UIImage.gifImageWithData(logoImageData!)
        logoView.image = logoGifImage
        addSubview(logoView)
    }

    @objc func flashLabels() {
        logoView.flash()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSize(size: CGSize) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        frame = rect
        logoView.frame = CGRect(x: frame.width / 2 - 40, y: frame.height / 2 - 40, width: 80, height: 80)
    }
}
