//
//  Dropdown.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-05.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject

protocol DropdownDelegate: AnyObject {
    func optionSelected(dropdown: Dropdown,
                        option: String,
                        relatedIndex: Int)
}

class Dropdown: UITableView {

    weak var dropDownDelegate: DropdownDelegate?
    var options = [String]() {
        didSet {
            self.prepareTableView()
        }
    }
    var height: CGFloat {
        return UIDevice.current.isIphone5orLess() ?
        CGFloat(self.options.count * 27) : CGFloat(self.options.count * 45)
    }
    var width: CGFloat = 124
    var maxHeight: CGFloat = 275
    var relatedIndex: Int = 0
    let reuseIdentifier = "dropdownCell"
    var attachedView: UIView?
    lazy var themeManager = Assembler.resolve(ThemeManager.self)
    var point: CGPoint {
        var minY: CGFloat = attachedView?.frame.minY ?? 0
        var maxX: CGFloat = attachedView?.frame.maxX ?? 0

        if attachedView is UITableViewCell {
            minY += attachedView?.frame.height ?? 0
            maxX -= 16
        }

        return CGPoint(x: maxX, y: minY)
    }

    init(attachedView: UIView) {
        super.init(frame: CGRect(x: attachedView.frame.maxX, y: attachedView.frame.minY, width: 0, height: 0), style: .plain)
        self.attachedView = attachedView
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 3.0
        self.register(DropDownTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        self.rowHeight = 45
        self.separatorStyle = .none
        self.allowsSelection = true
        self.delegate = self
        self.dataSource = self
        self.displayForPrefferedAppearence()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func prepareTableView() {
        UIView.animate(withDuration: 0.25, animations: {
            if self.height <= 150 {
                self.frame = CGRect(x: self.point.x-self.width, y: self.point.y, width: self.width, height: self.height)
            } else {
                self.frame = CGRect(x: self.point.x-self.width, y: self.point.y, width: self.width, height: self.maxHeight)
            }
        }, completion: { (_) in
            self.flashScrollIndicators()
        })
    }

    func removeWithAnimation() {
//        UIView.animate(withDuration: 0.25, animations: {
//            for cell in self.visibleCells {
//                cell.layer.opacity = 0.0
//            }
//            self.frame = CGRect(x: self.point.x, y: self.point.y, width: 0, height: 0)
//        }) { _ in
//            self.removeFromSuperview()
//        }
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            guard let self = self else { return }
            for cell in self.visibleCells {
                cell.layer.opacity = 0.0
            }
            self.frame = CGRect(x: self.point.x, y: self.point.y, width: 0, height: 0)
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }

    func displayForPrefferedAppearence() {
        let isDark = themeManager.getIsDarkTheme()
        if !isDark {
            self.backgroundColor = UIColor.midnight
        } else {
            self.backgroundColor = UIColor.white
        }

    }

}

extension Dropdown: UITableViewDelegate, UITableViewDataSource, DropDownTableViewCellDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? DropDownTableViewCell ?? DropDownTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        cell.button.setTitle(self.options[indexPath.row], for: .normal)
        cell.row = indexPath.row
        cell.delegate = self
        return cell
    }

    func buttonTapped(row: Int) {
        let value = options[row]
        self.dropDownDelegate?.optionSelected(dropdown: self, option: value, relatedIndex: row)
        self.removeWithAnimation()
    }

}

protocol DropDownTableViewCellDelegate: AnyObject {
    func buttonTapped(row: Int)
}

class DropDownTableViewCell: UITableViewCell {

    var button = UIButton()
    weak var delegate: DropDownTableViewCellDelegate?
    var row: Int = 0
    lazy var themeManager = Assembler.resolve(ThemeManager.self)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white

        button.titleLabel?.font = UIFont.text(size: 16)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(UIColor.midnight, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.contentView.addSubview(button)

        self.displayForPrefferedAppearence()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.translatesAutoresizingMaskIntoConstraints = false

        self.addConstraints([
         NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 20),
         NSLayoutConstraint(item: button, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -20),
         NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
         NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
         ])
    }

    @objc func buttonTapped() {
        self.delegate?.buttonTapped(row: self.row)
    }

    func displayForPrefferedAppearence() {
        let isDark = themeManager.getIsDarkTheme()
        if !isDark {
            self.backgroundColor = UIColor.midnight
            button.setTitleColor(UIColor.white, for: .normal)
        } else {
            self.backgroundColor = UIColor.white
            button.setTitleColor(UIColor.midnight, for: .normal)
        }
    }

}
