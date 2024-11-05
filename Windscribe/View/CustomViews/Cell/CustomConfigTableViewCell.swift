//
//  CustomConfigTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class CustomConfigTableViewCell: WTableViewCell {
    var nameLabel = UILabel()
    var signalBarsIcon = UIImageView()
    var latencyLabel: UILabel!
    var latencyBackground: UIView!
    var cellDivider = UIView()
    var displayingCustomConfig: CustomConfigModel? {
        didSet {
            updateUI()
        }
    }

    lazy var preferences = Assembler.resolve(Preferences.self)
    lazy var latenyRepo = Assembler.resolve(LatencyRepository.self)
    let disposeBag = DisposeBag()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setPressState(active: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setPressState(active: false)
    }

    override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
        setPressState(active: false)
    }

    private func setPressState(active: Bool) {
        if active {
            nameLabel.layer.opacity = 1
            signalBarsIcon.layer.opacity = 1
            latencyLabel.layer.opacity = 1
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.nameLabel.layer.opacity = 0.4
                self?.signalBarsIcon.layer.opacity = 0.4
                self?.latencyLabel.layer.opacity = 0.4
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.clear

        nameLabel.font = UIFont.bold(size: 14)
        nameLabel.textColor = UIColor.midnight
        nameLabel.layer.opacity = 0.4
        addSubview(nameLabel)
        latencyBackground = UIView()
        latencyBackground.backgroundColor = UIColor.midnight
        latencyBackground.layer.opacity = 0.05
        latencyBackground.layer.cornerRadius = 8
        latencyBackground.clipsToBounds = true
        addSubview(latencyBackground)
        latencyLabel = UILabel()
        latencyLabel.font = UIFont.bold(size: 12)
        latencyLabel.layer.opacity = 0.4
        latencyLabel.textColor = UIColor.midnight
        addSubview(latencyLabel)
        signalBarsIcon = UIImageView()
        signalBarsIcon.layer.opacity = 0.4
        signalBarsIcon.image = UIImage(named: ImagesAsset.CellSignalBars.full)
        addSubview(signalBarsIcon)
        cellDivider.backgroundColor = UIColor.seperatorGray
        addSubview(cellDivider)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        latencyBackground.translatesAutoresizingMaskIntoConstraints = false
        latencyLabel.translatesAutoresizingMaskIntoConstraints = false
        signalBarsIcon.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: nameLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: nameLabel as Any, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: nameLabel as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -65),
        ])
        addConstraints([
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .centerY, relatedBy: .equal, toItem: nameLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .width, relatedBy: .equal, toItem: latencyLabel, attribute: .width, multiplier: 1.0, constant: 0),
        ])
        addConstraints([
            NSLayoutConstraint(item: latencyLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: latencyBackground, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: latencyLabel as Any, attribute: .centerX, relatedBy: .equal, toItem: latencyBackground, attribute: .centerX, multiplier: 1.0, constant: 0),
        ])
        addConstraints([
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .centerY, relatedBy: .equal, toItem: nameLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: cellDivider as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
        ])
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(onNext: { isDarkMode in
            if !isDarkMode {
                self.cellDivider.backgroundColor = UIColor.seperatorWhite
                self.nameLabel.textColor = UIColor.midnight
                self.latencyLabel.textColor = UIColor.midnight
                self.latencyBackground.backgroundColor = UIColor.midnight
            } else {
                self.cellDivider.backgroundColor = UIColor.seperatorGray
                self.nameLabel.textColor = UIColor.white
                self.latencyLabel.textColor = UIColor.white
                self.latencyBackground.backgroundColor = UIColor.white
            }
        }).disposed(by: disposeBag)
    }

    func updateUI() {
        preferences.getLatencyType().subscribe(onNext: { latency in
            if latency == Fields.Values.ms {
                self.latencyBackground.isHidden = false
                self.latencyLabel.isHidden = false
                self.signalBarsIcon.isHidden = true
            } else {
                self.signalBarsIcon.isHidden = false
                self.latencyBackground.isHidden = true
                self.latencyLabel.isHidden = true
            }
        }).disposed(by: disposeBag)
        nameLabel.text = displayingCustomConfig?.name

        if let serverAddress = displayingCustomConfig?.serverAddress, let minTime = latenyRepo.getPingData(ip: serverAddress)?.latency {
            latencyLabel.text = "  \(minTime.description)  "
            switch getSignalLevel(minTime: minTime) {
            case 1:
                signalBarsIcon.image = cellSignalBarsLow
            case 2:
                signalBarsIcon.image = cellSignalBarsMed
            case 3:
                signalBarsIcon.image = cellSignalBarsFull
            default:
                signalBarsIcon.image = cellSignalBarsFull
            }
        } else {
            signalBarsIcon.image = cellSignalBarsFull
            latencyLabel.text = "  --  "
        }
    }
}
