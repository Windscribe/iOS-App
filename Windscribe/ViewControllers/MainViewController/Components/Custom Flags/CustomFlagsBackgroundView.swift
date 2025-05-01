//
//  FlagsBackgroundView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol FlagsBackgroundViewModelType {
    var locationSubject: BehaviorSubject<LocationUIInfo?> { get }
    var customBackgroundSubject: BehaviorSubject<Bool> { get }
    var colorSubject: BehaviorSubject<UIColor> { get }
    
}

class FlagsBackgroundViewModel: FlagsBackgroundViewModelType {
    let locationSubject = BehaviorSubject<LocationUIInfo?>(value: nil)
    let customBackgroundSubject = BehaviorSubject<Bool>(value: false)
    let colorSubject = BehaviorSubject<UIColor>(value: .nightBlue)
    
    let disposeBag = DisposeBag()
    
    var currentCountry: String = ""
    
    init(preferences: Preferences,
         locationsManager: LocationsManagerType,
         vpnManager: VPNManager) {
        locationsManager.selectedLocationUpdatedSubject.subscribe { [weak self] _ in
            guard let self = self else { return }
            let locationInfo = locationsManager.getLocationUIInfo()
            if self.currentCountry != locationInfo.countryCode {
                self.locationSubject.onNext(locationInfo)
                self.currentCountry = locationInfo.countryCode
            }
        }.disposed(by: disposeBag)
        
        vpnManager.getStatus().subscribe(onNext: { state in
            self.colorSubject.onNext(state == .connected ? .navyBlue : .nightBlue)
        }).disposed(by: disposeBag)
    }
}

class FlagsBackgroundView: UIView {
    let disposeBag = DisposeBag()
    
    var viewModel: FlagsBackgroundViewModelType! {
        didSet {
            bindViewModel()
        }
    }
    
    var flagView = UIImageView()
    var topMaskGradient = TopMaskGradientView()
    var topNavBarHeader = TopNavBarHeader()
    var topView = UIView()
    
    var flagHeight: CGFloat {
        272
    }
    var flagWidth: CGFloat {
        402
    }
    var height: CGFloat {
        flagHeight + topNavBarHeader.height
    }
    var barHeight: CGFloat {
        topNavBarHeader.height
    }
    var topViewHeight: CGFloat {
        if UIScreen.hasTopNotch {
            return 40
        } else if UIDevice.current.isIpad {
            return 20
        }
        return 16
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: .zero)
        addViews()
        setLayout()
    }
    
    func redraw() {
        topMaskGradient.redrawGradient()
        topNavBarHeader.redrawGradient()
    }
    
    func changeFlag(to flagName: String, isCustom: Bool = false) {
        if !isCustom, let newFlag = UIImage(named: flagName) {
            flagView.alpha = 0.15
            topMaskGradient.isHidden = false
            if flagView.image == nil {
                flagView.image = newFlag
            } else {
                slideNewImageUp(flagView, to: newFlag)
            }
            return
        }
        flagView.image = UIImage(named: ImagesAsset.Backgrounds.one)
        flagView.alpha = 1.0
        topMaskGradient.isHidden = true
    }
    
    private func bindViewModel() {
        Observable.combineLatest(viewModel.locationSubject, viewModel.customBackgroundSubject)
            .observe(on: MainScheduler.instance).subscribe { [weak self] (locationInfo, isCustom) in
                self?.changeFlag(to: locationInfo?.countryCode ?? "", isCustom: isCustom)
            }.disposed(by: disposeBag)
        
        viewModel.colorSubject.subscribe(onNext: { [weak self] color in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.topMaskGradient.currentColor = color.cgColor
                self.backgroundColor = color
                self.topView.backgroundColor = color
            }
        }).disposed(by: disposeBag)
    }
    
    private func addViews() {
        flagView.image = UIImage(named: ImagesAsset.Backgrounds.one)
        flagView.isUserInteractionEnabled = false
        flagView.contentMode = .scaleAspectFill
        flagView.setImageColor(color: .white)
        addSubview(flagView)
        addSubview(topView)
        addSubview(topMaskGradient)
        addSubview(topNavBarHeader)
    }
    
    private func setLayout() {
        flagView.translatesAutoresizingMaskIntoConstraints = false
        topMaskGradient.translatesAutoresizingMaskIntoConstraints = false
        topNavBarHeader.translatesAutoresizingMaskIntoConstraints = false
        topView.translatesAutoresizingMaskIntoConstraints = false
        let flagWidthConstraint = UIDevice.current.isIpad ?
        flagView.widthAnchor.constraint(equalTo: widthAnchor) :
        flagView.widthAnchor.constraint(equalToConstant: flagWidth)
        
        NSLayoutConstraint.activate([
            // topView
            topView.topAnchor.constraint(equalTo: topAnchor),
            topView.leftAnchor.constraint(equalTo: leftAnchor),
            topView.rightAnchor.constraint(equalTo: rightAnchor),
            topView.heightAnchor.constraint(equalToConstant: topViewHeight),
            
            // topNavBarLeftImageView
            topNavBarHeader.topAnchor.constraint(equalTo: topAnchor),
            topNavBarHeader.rightAnchor.constraint(equalTo: rightAnchor),
            topNavBarHeader.leftAnchor.constraint(equalTo: leftAnchor),
            topNavBarHeader.heightAnchor.constraint(equalToConstant: topNavBarHeader.height),
            
            // flagView
            flagView.topAnchor.constraint(equalTo: topView.bottomAnchor),
            flagView.bottomAnchor.constraint(equalTo: bottomAnchor),
            flagView.centerXAnchor.constraint(equalTo: centerXAnchor),
            flagView.heightAnchor.constraint(equalToConstant: flagHeight),
            flagWidthConstraint,
            
            // topMaskGradient
            topMaskGradient.topAnchor.constraint(equalTo: topView.bottomAnchor),
            topMaskGradient.bottomAnchor.constraint(equalTo: bottomAnchor),
            topMaskGradient.centerXAnchor.constraint(equalTo: centerXAnchor),
            topMaskGradient.heightAnchor.constraint(equalTo: flagView.heightAnchor),
            topMaskGradient.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }
}
