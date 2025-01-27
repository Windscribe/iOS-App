//
//  WSUIViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-20.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension WSUIViewController {
    func addGetMoreDataViews() {
        getMoreDataView = UIImageView()
        getMoreDataView.isUserInteractionEnabled = true
        view.addSubview(getMoreDataView)
        getMoreDataView.addTopDivider(color: .seaGreen, height: 2, paddingLeft: 0)
        getMoreDataView.backgroundColor = .black
        getMoreDataLabel = UILabel()
        getMoreDataLabel.adjustsFontSizeToFitWidth = true
        getMoreDataLabel.font = UIFont.bold(size: 12)
        getMoreDataLabel.textColor = UIColor.seaGreen
        view.addSubview(getMoreDataLabel)

        getMoreDataButton = UIButton(type: .system)
        getMoreDataButton.addTarget(self, action: #selector(getMoreDataButtonTapped), for: .touchUpInside)
        getMoreDataButton.layer.opacity = 0.5
        getMoreDataButton.titleLabel?.adjustsFontSizeToFitWidth = true
        getMoreDataButton.titleLabel?.font = UIFont.bold(size: 12)
        getMoreDataButton.setTitleColor(UIColor.white, for: .normal)
        getMoreDataButton.setTitle(TextsAsset.getMoreData.uppercased(), for: .normal)
        view.addSubview(getMoreDataButton)
    }

    func addAutolayoutConstraintsForGetMoreDataViews() {
        getMoreDataView.translatesAutoresizingMaskIntoConstraints = false
        getMoreDataLabel.translatesAutoresizingMaskIntoConstraints = false
        getMoreDataButton.translatesAutoresizingMaskIntoConstraints = false

        if UIScreen.hasTopNotch {
            view.addConstraints([
                NSLayoutConstraint(item: getMoreDataView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50),
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: getMoreDataLabel as Any, attribute: .bottom, relatedBy: .equal, toItem: getMoreDataView, attribute: .bottom, multiplier: 1.0, constant: -8),
            ])
        }
        view.addConstraints([
            NSLayoutConstraint(item: getMoreDataLabel as Any, attribute: .top, relatedBy: .equal, toItem: getMoreDataView, attribute: .top, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: getMoreDataButton as Any, attribute: .top, relatedBy: .equal, toItem: getMoreDataView, attribute: .top, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: getMoreDataLabel as Any, attribute: .left, relatedBy: .equal, toItem: getMoreDataView, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: getMoreDataButton as Any, attribute: .right, relatedBy: .equal, toItem: getMoreDataView, attribute: .right, multiplier: 1.0, constant: -16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: getMoreDataView as Any, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: getMoreDataView as Any, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: getMoreDataView as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: getMoreDataView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: getMoreDataLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: getMoreDataButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])
    }

    func showGetMoreDataViews() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.getMoreDataView.layer.opacity = 1.0
            self?.getMoreDataLabel.layer.opacity = 1.0
            self?.getMoreDataButton.layer.opacity = 1.0
        }
    }

    func hideGetMoreDataViews() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.getMoreDataView.layer.opacity = 0.2
            self?.getMoreDataLabel.layer.opacity = 0.2
            self?.getMoreDataButton.layer.opacity = 0.2
        }
    }
}
