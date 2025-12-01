//
//  FreeAccountFooterView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import Swinject
import Combine

protocol FreeAccountFooterViewModelType {
    var dataLeftSubject: BehaviorSubject<DataLeftModel?> { get }
}

class FreeAccountFooterViewModel: FreeAccountFooterViewModelType {
    let dataLeftSubject = BehaviorSubject<DataLeftModel?>(value: nil)

    private var cancellables = Set<AnyCancellable>()

    init(userSessionRepository: UserSessionRepository) {
        userSessionRepository.sessionModelSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.dataLeftSubject.onNext(session?.getDataLeftModel())
            }
            .store(in: &cancellables)
    }
}

protocol FreeAccountFooterViewDelegate: AnyObject {
    func freeAccountFooterTapped()
    func updateFooterViewVisibility(visible: Bool)
}

class FreeAccountFooterView: UIView {
    let disposeBag = DisposeBag()

    weak var delegate: FreeAccountFooterViewDelegate?

    var contentView = UIView()
    var backgroundView = UIView()
    var completionCircleView = CompletionCircleView(lineWidth: 3, radius: 20)
    var dataLeftLabel = UILabel()
    var unitLabel = UILabel()
    var headerLabel = UILabel()
    var bodyLabel = UILabel()
    var actionButton = UIButton()
    var actionIcon = UIImageView()

    var viewModel: FreeAccountFooterViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        addViews()
        setLayout()
    }

    private func bindViewModel() {
        viewModel.dataLeftSubject.subscribe { [weak self] dataLeft in
            self?.updateDataInfo(dataLeft)
        }.disposed(by: disposeBag)

        actionButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.delegate?.freeAccountFooterTapped()
        }.disposed(by: disposeBag)
    }

    private func updateDataInfo(_ dataLeft: DataLeftModel?) {
        guard let dataLeft = dataLeft else { return }
        if dataLeft.isPro {
            isHidden = true
            delegate?.updateFooterViewVisibility(visible: false)
        } else {
            isHidden = false
            delegate?.updateFooterViewVisibility(visible: true)
            completionCircleView.percentage = dataLeft.percentage
            dataLeftLabel.text = dataLeft.dataLeft
            unitLabel.text = dataLeft.unit
            dataLeftLabel.textColor = completionCircleView.getColorFromPercentage()
            unitLabel.textColor = completionCircleView.getColorFromPercentage()

            if dataLeft.percentage == 0.0 {
                headerLabel.text = TextsAsset.FreeAccount.outOfDataHeader
            } else {
                headerLabel.text = TextsAsset.FreeAccount.header
            }
        }
    }

    private func addViews() {
        backgroundColor = .clear

        backgroundView.backgroundColor = .whiteWithOpacity(opacity: 0.05)

        contentView.backgroundColor = .nightBlue
        contentView.layer.cornerRadius = 8
        contentView.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.1).cgColor
        contentView.layer.borderWidth = 1
        contentView.layer.masksToBounds = true
        contentView.clipsToBounds = true

        dataLeftLabel.textAlignment = .center
        dataLeftLabel.adjustsFontSizeToFitWidth = true
        dataLeftLabel.textColor = UIColor.seaGreen
        dataLeftLabel.font = UIFont.medium(size: 9)

        unitLabel.textAlignment = .center
        unitLabel.adjustsFontSizeToFitWidth = true
        unitLabel.textColor = UIColor.seaGreen
        unitLabel.layer.opacity = 0.7
        unitLabel.font = UIFont.medium(size: 8)

        headerLabel.textAlignment = .left
        headerLabel.adjustsFontSizeToFitWidth = true
        headerLabel.font = UIFont.regular(size: 15)
        headerLabel.textColor = UIColor.white
        headerLabel.text = TextsAsset.FreeAccount.header

        bodyLabel.textAlignment = .left
        bodyLabel.adjustsFontSizeToFitWidth = true
        bodyLabel.font = UIFont.regular(size: 12)
        bodyLabel.textColor = UIColor.cyberBlue
        bodyLabel.text = TextsAsset.FreeAccount.body

        actionIcon.image = UIImage(named: ImagesAsset.serverWhiteRightArrow)
        actionIcon.setImageColor(color: .whiteWithOpacity(opacity: 0.4))
        actionIcon.contentMode = .scaleAspectFit

        addSubview(contentView)
        contentView.addSubview(backgroundView)
        contentView.addSubview(dataLeftLabel)
        contentView.addSubview(unitLabel)
        contentView.addSubview(headerLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(completionCircleView)
        contentView.addSubview(actionIcon)
        contentView.addSubview(actionButton)
    }

    private func setLayout() {
        super.layoutSubviews()

        contentView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        completionCircleView.translatesAutoresizingMaskIntoConstraints = false
        dataLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        actionIcon.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // contentView
            contentView.heightAnchor.constraint(equalToConstant: 62),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),

            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            backgroundView.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            // actionButton
            actionButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            actionButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            actionButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            // completionCircleView
            completionCircleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            completionCircleView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
            completionCircleView.heightAnchor.constraint(equalToConstant: 40),
            completionCircleView.widthAnchor.constraint(equalToConstant: 40),

            // dataLeftLabel
            dataLeftLabel.centerXAnchor.constraint(equalTo: completionCircleView.centerXAnchor),
            dataLeftLabel.topAnchor.constraint(equalTo: completionCircleView.topAnchor, constant: 10),

            // unitLabel
            unitLabel.centerXAnchor.constraint(equalTo: completionCircleView.centerXAnchor),
            unitLabel.bottomAnchor.constraint(equalTo: completionCircleView.bottomAnchor, constant: -9),

            // actionIcon
            actionIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionIcon.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
            actionIcon.heightAnchor.constraint(equalToConstant: 16),
            actionIcon.widthAnchor.constraint(equalToConstant: 16),

            // headerLabel
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            headerLabel.leftAnchor.constraint(equalTo: completionCircleView.rightAnchor, constant: 16),
            headerLabel.rightAnchor.constraint(equalTo: actionIcon.rightAnchor),

            // bodyLabel
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            bodyLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor),
            bodyLabel.leftAnchor.constraint(equalTo: completionCircleView.rightAnchor, constant: 16),
            bodyLabel.rightAnchor.constraint(equalTo: actionIcon.rightAnchor)
        ])
    }
}

extension MainViewController: FreeAccountFooterViewDelegate {
    func freeAccountFooterTapped() {
        popupRouter?.routeTo(to: .upgrade(promoCode: nil, pcpID: nil), from: self)
    }

    func updateFooterViewVisibility(visible: Bool) {
        serverListTableView.verticalScrollIndicatorInsets.bottom = visible ? 100 : 0
    }
}
