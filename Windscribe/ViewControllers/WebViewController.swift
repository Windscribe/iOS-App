//
//  WebViewController.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-11-11.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebViewController: WSNavigationViewController {
    var webview: WKWebView!
    var path: String!
    var autoLogin = true

    override func viewDidLoad() {
        super.viewDidLoad()
        LogManager.shared.log(activity: String(describing: HelpViewController.self), text: "Displaying Web View", type: .Debug)
        titleLabel.text = Web.Windscribe
        addViews()
        addAutoLayoutConstraints()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayElementsForPrefferedAppearence),
            name: Notifications.AppearancePreferenceChanged,
            object: nil
        )

        guard let request = createUrlRequest(
            path: Links.acccount,
            autoLogin: true
        ) else { return }
        load(urlRequest: request)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayElementsForPrefferedAppearence()
    }

    func createUrlRequest(path: String, autoLogin: Bool) -> URLRequest? {
        let urlPath = Links.base + path
        guard let url = URL(string: urlPath) else { return nil }
        var urlRequest = URLRequest(url: url)
        if autoLogin {
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            guard let sessionAuthHash = NetworkManager.shared.activeSessionAuthHash else { return nil }
            let postString = "app_session=\(sessionAuthHash)"
            print("dsdfs \(postString)")
            urlRequest.httpBody = postString.data(using: .utf8)
        }
        return urlRequest
    }
}
