//
//	UITableViewCell.swift
//	Windscribe
//
//	Created by Thomas on 25/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

// MARK: - UITableView register and dequeue

extension UITableViewCell {
    class func registerClass(in tableView: UITableView?) {
        tableView?.register(self, forCellReuseIdentifier: className)
    }

    class func registerNibClass(in tableView: UITableView?) {
        tableView?.register(UINib(nibName: className, bundle: nil), forCellReuseIdentifier: className)
    }

    class func dequeueReusableCell(in tableView: UITableView, for indexPath: IndexPath) -> Self {
        let cell = tableView.dequeueReusableCell(withIdentifier: className, for: indexPath)
        return cell as? Self ?? self.init()
    }

    private static var className: String {
        String(describing: self)
    }
}
