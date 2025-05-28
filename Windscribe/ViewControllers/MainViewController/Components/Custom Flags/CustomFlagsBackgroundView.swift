//
//  FlagsBackgroundView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

struct BackgroundInfoModel {
    let image: UIImage?
    let animates: Bool
    let color: UIColor
    let aspectRatioType: BackgroundAspectRatioType
    var effect: BackgroundEffectType = .flag
}

protocol FlagsBackgroundViewModelType {
    var backgroundInfoSubject: BehaviorSubject<BackgroundInfoModel?> { get }
}

class FlagsBackgroundViewModel: FlagsBackgroundViewModelType {
    let backgroundInfoSubject = BehaviorSubject<BackgroundInfoModel?>(value: nil)

    let disposeBag = DisposeBag()
    let locationsManager: LocationsManagerType
    let lookAndFeelRepository: LookAndFeelRepositoryType
    let backgroundFileManager: BackgroundFileManaging

    var currentCountry: String = ""

    private var isConnected = false

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         locationsManager: LocationsManagerType,
         vpnManager: VPNManager,
         backgroundFileManager: BackgroundFileManaging) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.locationsManager = locationsManager
        self.backgroundFileManager = backgroundFileManager

        locationsManager.selectedLocationUpdatedSubject.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.updateBackgroundImage(isConnected: self.isConnected)
        }).disposed(by: disposeBag)

        lookAndFeelRepository.backgroundChangedTrigger.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.updateBackgroundImage(isConnected: self.isConnected)
        }).disposed(by: disposeBag)

        vpnManager.getStatus().subscribe(onNext: { [weak self] state in
            guard let self = self else { return }
            self.isConnected = state == .connected
            self.updateBackgroundImage(isConnected: self.isConnected)
        }).disposed(by: disposeBag)
    }

    private func updateBackgroundImage(isConnected: Bool) {
        var effect = BackgroundEffectType.flag
        if isConnected {
            effect = lookAndFeelRepository.backgroundEffectConnect
        } else if !isConnected {
            effect = lookAndFeelRepository.backgroundEffectDisconnect
        }
        backgroundInfoSubject.onNext(getBackgroundInfoModel(for: effect,
                                                            isConnected: isConnected))
    }

    private func getBackgroundInfoModel(for effect: BackgroundEffectType,
                                        isConnected: Bool) -> BackgroundInfoModel {
        let color: UIColor = isConnected ? .navyBlue : .nightBlue
        let aspectRatio = lookAndFeelRepository.backgroundCustomAspectRatio
        switch effect {
        case .bundled(subtype: let subtype):
            if let image = UIImage(named: subtype.assetName) {
                return BackgroundInfoModel(image: image, animates: false,
                                           color: color, aspectRatioType: aspectRatio,
                                           effect: effect)
            }
        case .custom:
            if let image = getImageURL(isConnected) {
                return BackgroundInfoModel(image: image, animates: false,
                                           color: color, aspectRatioType: aspectRatio,
                                           effect: effect)
            }
        case .none:
            return BackgroundInfoModel(image: nil, animates: false,
                                       color: .clear, aspectRatioType: aspectRatio,
                                       effect: effect)
        default: break
        }
        return getLocationInfo(color: color)
    }

    private func getLocationInfo(color: UIColor) -> BackgroundInfoModel {
        let flagName = locationsManager.getLocationUIInfo().countryCode
        let animates = currentCountry != flagName
        currentCountry = flagName
        return BackgroundInfoModel(image: UIImage(named: flagName), animates: animates, color: color, aspectRatioType: .stretch)
    }

    private func getImageURL(_ isconnected: Bool) -> UIImage? {
        let url: URL? = backgroundFileManager.getImageURL(for: isconnected ? .connect : .disconnect)
        if let url = url,
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }
}

class FlagsBackgroundView: UIView {
    let disposeBag = DisposeBag()

    var viewModel: FlagsBackgroundViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    var backgroundImageView = UIImageView()
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

    func changebackground(for info: BackgroundInfoModel) {
        switch info.effect {
        case .none:
            backgroundImageView.alpha = 0.0
        case .flag:
            backgroundImageView.alpha = 0.15
        default:
            backgroundImageView.alpha = 1.0
        }
        if info.animates, let newImage = info.image {
            if backgroundImageView.image == nil {
                backgroundImageView.image = newImage
            } else {
                slideNewImageUp(backgroundImageView, to: newImage)
            }
            return
        }

        backgroundImageView.image = info.image
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.backgroundColor = .clear
        if info.effect == .custom {
            if info.aspectRatioType == .fill {
                backgroundImageView.contentMode = .scaleToFill
            } else if info.aspectRatioType == .tile, let image = info.image {
                backgroundImageView.image = nil
                backgroundImageView.backgroundColor = UIColor(patternImage: image)
            }
        }
    }

    private func bindViewModel() {
        viewModel.backgroundInfoSubject.subscribe(onNext: { [weak self] info in
            guard let self = self, let info = info else { return }
            DispatchQueue.main.async {
                self.topMaskGradient.currentColor = info.color.cgColor
                self.backgroundColor = info.color
                self.topView.backgroundColor = info.color
                self.changebackground(for: info)
            }
        }).disposed(by: disposeBag)
    }

    private func addViews() {
        backgroundImageView.image = UIImage(named: ImagesAsset.Backgrounds.one)
        backgroundImageView.isUserInteractionEnabled = false
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.setImageColor(color: .white)
        addSubview(backgroundImageView)
        addSubview(topView)
        addSubview(topMaskGradient)
        addSubview(topNavBarHeader)
    }

    private func setLayout() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        topMaskGradient.translatesAutoresizingMaskIntoConstraints = false
        topNavBarHeader.translatesAutoresizingMaskIntoConstraints = false
        topView.translatesAutoresizingMaskIntoConstraints = false
        let flagWidthConstraint = UIDevice.current.isIpad ?
        backgroundImageView.widthAnchor.constraint(equalTo: widthAnchor) :
        backgroundImageView.widthAnchor.constraint(equalToConstant: flagWidth)

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
            backgroundImageView.topAnchor.constraint(equalTo: topView.bottomAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundImageView.heightAnchor.constraint(equalToConstant: flagHeight),
            flagWidthConstraint,

            // topMaskGradient
            topMaskGradient.topAnchor.constraint(equalTo: topView.bottomAnchor),
            topMaskGradient.bottomAnchor.constraint(equalTo: bottomAnchor),
            topMaskGradient.centerXAnchor.constraint(equalTo: centerXAnchor),
            topMaskGradient.heightAnchor.constraint(equalTo: backgroundImageView.heightAnchor),
            topMaskGradient.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }
}
