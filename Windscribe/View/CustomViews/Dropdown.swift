//
//  Dropdown.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-05.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Swinject
import UIKit

protocol DropdownDelegate: AnyObject {
    func optionSelected(dropdown: Dropdown,
                        option: String,
                        relatedIndex: Int)
}

class Dropdown: UITableView {
    weak var dropDownDelegate: DropdownDelegate?
    var options = [String]() {
        didSet {
            prepareTableView()
        }
    }

    var height: CGFloat {
        return UIDevice.current.isIphone5orLess() ?
            CGFloat(options.count * 27) : CGFloat(options.count * 45)
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
        backgroundColor = UIColor.white
        layer.cornerRadius = 3.0
        register(DropDownTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        rowHeight = 45
        separatorStyle = .none
        allowsSelection = true
        delegate = self
        dataSource = self
        displayForPrefferedAppearence()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func prepareTableView() {
        UIView.animate(withDuration: 0.25, animations: {
            self.frame = CGRect(x: self.point.x - self.width, y: self.point.y, width: self.width, height: min(self.height, self.maxHeight))
        }, completion: { _ in
            self.flashScrollIndicators()
        })
    }

    func removeWithAnimation() {
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
            backgroundColor = UIColor.midnight
        } else {
            backgroundColor = UIColor.white
        }
    }
}

extension Dropdown: UITableViewDelegate, UITableViewDataSource, DropDownTableViewCellDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? DropDownTableViewCell ?? DropDownTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        cell.button.setTitle(options[indexPath.row], for: .normal)
        cell.row = indexPath.row
        cell.delegate = self
        return cell
    }

    func buttonTapped(row: Int) {
        let value = options[row]
        dropDownDelegate?.optionSelected(dropdown: self, option: value, relatedIndex: row)
        removeWithAnimation()
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
        backgroundColor = UIColor.white

        button.titleLabel?.font = UIFont.text(size: 16)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(UIColor.midnight, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        contentView.addSubview(button)

        displayForPrefferedAppearence()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: button, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -20),
            NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
    }

    @objc func buttonTapped() {
        delegate?.buttonTapped(row: row)
    }

    func displayForPrefferedAppearence() {
        let isDark = themeManager.getIsDarkTheme()
        if !isDark {
            backgroundColor = UIColor.midnight
            button.setTitleColor(UIColor.white, for: .normal)
        } else {
            backgroundColor = UIColor.white
            button.setTitleColor(UIColor.midnight, for: .normal)
        }
    }
}
