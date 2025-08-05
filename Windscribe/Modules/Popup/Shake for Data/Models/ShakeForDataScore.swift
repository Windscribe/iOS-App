//
//  Score.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-13.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RxDataSources
import UIKit

struct ShakeForDataLeaderboardEntry: Identifiable {
    let id = UUID()
    let score: Int
    let user: String
    let you: Bool
}

class ShakeForDataScore: Decodable {
    var score: Int = 0
    var user: String = ""
    var you: Bool = false

    enum CodingKeys: String, CodingKey {
        case score
        case user
        case you
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
        user = try container.decodeIfPresent(String.self, forKey: .user) ?? ""
        you = try container.decodeIfPresent(Int.self, forKey: .you) == 1 ? true : false
    }

    func toLeaderboardEntry() -> ShakeForDataLeaderboardEntry {
        ShakeForDataLeaderboardEntry(score: score, user: user, you: you)
    }
}

struct ShakeForDataScoreSection: SectionModelType {
    init(original: ShakeForDataScoreSection, items: [ShakeForDataScore]) {
        self = original
        self.items = items
    }

    init(items: [ShakeForDataScore]) {
        self.items = items
    }

    var title: String = ""
    var items: [ShakeForDataScore]
}

struct ShakeForDataScoreList {}

class Leaderboard: Decodable {
    var scores = [ShakeForDataScore]()

    enum CodingKeys: String, CodingKey {
        case data
        case leaderboard
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        if let scoreArray = try data.decodeIfPresent([ShakeForDataScore].self, forKey: .leaderboard) {
            setScores(array: scoreArray)
        }
    }

    func setScores(array: [ShakeForDataScore]) {
        scores.removeAll()
        scores.append(contentsOf: array)
    }
}
