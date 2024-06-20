//
//  WelcomeViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2020-12-08.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension WelcomeViewController {

    func configureViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.clear
        view.addSubview(backgroundView)

        backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = UIImage(named: "welcome-background.png")
        view.addSubview(backgroundImageView)

        bottomGradientView = UIImageView(frame: CGRect(x: 0, y: self.view.frame.height/2, width: self.view.frame.width, height: self.view.frame.height/2))
        bottomGradientView.contentMode = .scaleAspectFill
        bottomGradientView.image = UIImage(named: "welcome-gradient.png")
        view.addSubview(bottomGradientView)

        pageControl = UIPageControl()
        pageControl.numberOfPages = 4
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.whiteWithOpacity(opacity: 0.25)
        pageControl.currentPageIndicatorTintColor = UIColor.white
        view.addSubview(pageControl)

        scrollView = WScrollView()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(width: self.view.frame.width*4, height: 0)
        view.addSubview(scrollView)

        infoLabel1 = UILabel()
        infoLabel1.textAlignment = .center
        infoLabel1.textColor = UIColor.white
        infoLabel1.font = UIFont.text(size: 16)
        infoLabel1.layer.opacity = 0.5
        scrollView.addSubview(infoLabel1)

        infoLabel2 = UILabel()
        infoLabel2.textAlignment = .center
        infoLabel2.textColor = UIColor.white
        infoLabel2.font = UIFont.text(size: 16)
        infoLabel2.layer.opacity = 0.5
        scrollView.addSubview(infoLabel2)

        infoLabel3 = UILabel()
        infoLabel3.textAlignment = .center
        infoLabel3.textColor = UIColor.white
        infoLabel3.font = UIFont.text(size: 16)
        infoLabel3.layer.opacity = 0.5
        scrollView.addSubview(infoLabel3)

        infoLabel4 = UILabel()
        infoLabel4.textAlignment = .center
        infoLabel4.textColor = UIColor.white
        infoLabel4.font = UIFont.text(size: 16)
        infoLabel4.layer.opacity = 0.5
        scrollView.addSubview(infoLabel4)

        logoButton = UIButton()
        let logoImageData = try? Data(contentsOf: Bundle.main.url(forResource: "ws-rotating-logo", withExtension: "gif")!)
        let logoGifImage = UIImage.gifImageWithData(logoImageData!)
        logoButton.setImage(logoGifImage, for: .normal)
        logoButton.isUserInteractionEnabled = false
        view.addSubview(logoButton)

        loginButton = UIButton(type: .system)
        loginButton.layer.opacity = 0.5
        loginButton.setTitleColor(UIColor.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.bold(size: 16)
        view.addSubview(loginButton)

        continueButton = UIButton(type: .system)
        continueButton.layer.cornerRadius = 26
        continueButton.clipsToBounds = true
        continueButton.backgroundColor = UIColor.seaGreen
        continueButton.setTitleColor(UIColor.black, for: .normal)
        continueButton.titleLabel?.font = UIFont.text(size: 16)
        continueButton.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(continueButton)

        emergencyConnect = UIButton(type: .system)
        view.addSubview(emergencyConnect)

        sloganLabel = UILabel()
        sloganLabel.textColor = UIColor.white
        sloganLabel.font = UIFont.bold(size: 32)
        sloganLabel.numberOfLines = 0
        sloganLabel.textAlignment = .center
        sloganLabel.adjustsFontSizeToFitWidth = true
        sloganLabel.minimumScaleFactor = 0.1
        view.addSubview(sloganLabel)

        loadingView = UIActivityIndicatorView(style: .white)
        loadingView.isHidden = true
        view.addSubview(loadingView)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel1.translatesAutoresizingMaskIntoConstraints = false
        infoLabel2.translatesAutoresizingMaskIntoConstraints = false
        infoLabel3.translatesAutoresizingMaskIntoConstraints = false
        infoLabel4.translatesAutoresizingMaskIntoConstraints = false
        logoButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        emergencyConnect.translatesAutoresizingMaskIntoConstraints = false
        sloganLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: backgroundView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])

        view.addConstraints([
            NSLayoutConstraint(item: backgroundImageView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundImageView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundImageView as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundImageView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])

        pageControl.makeTopAnchor(constant: 48)
        pageControl.makeCenterXAnchor()
        pageControl.makeHeightAnchor(equalTo: 8)

        view.addConstraints([
            NSLayoutConstraint(item: scrollView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .top, relatedBy: .equal, toItem: pageControl, attribute: .bottom, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: scrollView as Any, attribute: .bottom, relatedBy: .equal, toItem: logoButton, attribute: .top, multiplier: 1.0, constant: 0)
        ])

        self.view.addConstraints([
            NSLayoutConstraint(item: infoLabel1 as Any, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel1 as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: infoLabel1 as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: infoLabel2 as Any, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel2 as Any, attribute: .left, relatedBy: .equal, toItem: infoLabel1, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel2 as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: infoLabel2 as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: infoLabel3 as Any, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel3 as Any, attribute: .left, relatedBy: .equal, toItem: infoLabel2, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel3 as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: infoLabel3 as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: infoLabel4 as Any, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel4 as Any, attribute: .left, relatedBy: .equal, toItem: infoLabel3, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: infoLabel4 as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: infoLabel4 as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: logoButton as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: logoButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 56),
            NSLayoutConstraint(item: logoButton as Any, attribute: .centerY, relatedBy: .equal, toItem: self.backgroundView, attribute: .centerY, multiplier: 1.0, constant: -56),
            NSLayoutConstraint(item: logoButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 56)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: sloganLabel as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: sloganLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.logoButton, attribute: .bottom, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: sloganLabel as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 154),
            NSLayoutConstraint(item: sloganLabel as Any, attribute: .bottom, relatedBy: .equal, toItem: self.continueButton, attribute: .top, multiplier: 1.0, constant: -24)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: continueButton as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: continueButton as Any, attribute: .bottom, relatedBy: .equal, toItem: self.loginButton, attribute: .top, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: continueButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48),
            NSLayoutConstraint(item: continueButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 279)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: loginButton as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loginButton as Any, attribute: .bottom, relatedBy: .equal, toItem: self.emergencyConnect, attribute: .bottom, multiplier: 1.0, constant: -80),
            NSLayoutConstraint(item: loginButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: emergencyConnect as Any, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: emergencyConnect as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: -55),
            NSLayoutConstraint(item: emergencyConnect as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40),
            NSLayoutConstraint(item: emergencyConnect as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40)
        ])

        self.view.addConstraints([
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerY, relatedBy: .equal, toItem: self.continueButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: loadingView as Any, attribute: .centerX, relatedBy: .equal, toItem: self.continueButton, attribute: .centerX, multiplier: 1.0, constant: 0)
        ])
    }

    func hideLoadingView() {
        loadingView.isHidden = true
        continueButton.setTitle(TextsAsset.getStarted,
                                for: .normal)
    }

    func showLoadingView() {
        loadingView.startAnimating()
        loadingView.isHidden = false
        continueButton.setTitle(nil, for: .normal)
    }

    func setHeaderViewSelector() {
        switch scrollView.contentOffset.x {
        case 0:
            scrollOrder = 0
        case view.frame.width:
            scrollOrder = 1
        case view.frame.width * 2:
            scrollOrder = 2
        case view.frame.width * 3:
            scrollOrder = 3
        default:
            return
        }
        pageControl.currentPage = scrollOrder
    }

    @objc func slideScrollView() {
        scrollOrder += 1
        switch scrollOrder {
        case 0:
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        case 1:
            scrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: true)
        case 2:
            scrollView.setContentOffset(CGPoint(x: self.view.frame.width*2, y: 0), animated: true)
        case 3:
            scrollView.setContentOffset(CGPoint(x: self.view.frame.width*3, y: 0), animated: true)
            scrollOrder = -1
        default:
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            scrollOrder = 0
            return
        }
    }
}

extension WelcomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setHeaderViewSelector()
    }
}
