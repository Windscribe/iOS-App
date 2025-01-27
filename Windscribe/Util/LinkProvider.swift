//
//  LinkProvider.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-03-08.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

enum LinkProvider {
    static func getWindscribeLinkWithAutoLogin(path: String,
                                               tempSession: String) -> String
    {
        return Links.base + path + "?temp_session=\(tempSession)"
    }

    static func getRobertRulesUrl(session: String) -> URL? {
        let queryItems = [URLQueryItem(name: "temp_session", value: session)]
        var components = URLComponents()
        components.scheme = "https"
        components.host = Links.base.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "")
        components.path = "/myaccount"
        components.fragment = "robertrules"
        components.queryItems = queryItems
        return components.url
    }

    static func getWindscribeLink(path: String) -> String {
        return Links.base + path
    }
}
