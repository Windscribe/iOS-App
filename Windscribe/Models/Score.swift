//
//  Score.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-13.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RxDataSources

class Score: Decodable {
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
}

struct ScoreSection: SectionModelType {
    init(original: ScoreSection, items: [Score]) {
        self = original
        self.items = items
    }

    init(items: [Score]) {
        self.items = items
    }

    var title: String = ""
    var items: [Score]
}

struct ScoreList {}

class Leaderboard: Decodable {
    var scores = [Score]()

    enum CodingKeys: String, CodingKey {
        case data
        case leaderboard
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        if let scoreArray = try data.decodeIfPresent([Score].self, forKey: .leaderboard) {
            setScores(array: scoreArray)
        }
    }

    func setScores(array: [Score]) {
        scores.removeAll()
        scores.append(contentsOf: array)
    }
}
