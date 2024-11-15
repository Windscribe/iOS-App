//
//  NewsfeedDataSource.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-11-12.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class NewsfeedDataSource: NSObject, UITableViewDataSource {
    private var items: [NewsFeedData] = []
    var didTapExpandIcon: ((Int) -> Void)?
    var didTapAction: ((ActionLink) -> Void)?
    func setData(items: [NewsFeedData]) {
        self.items = items
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsFeedDataCell", for: indexPath) as? NewsFeedDataCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(with: item)
        cell.didTapExpandIcon = { [weak self] id in
            self?.didTapExpandIcon?(id)
        }
        cell.didTapActionLabel = { [weak self] action in
            self?.didTapAction?(action)
        }
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt _: IndexPath) {}
}
