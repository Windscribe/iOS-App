//
//  SampleDataLeaderboard.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-10-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

class SampleDataLeaderboard {
    static let leaderboardJSON = """
    {
        "data": {
            "leaderboard": [
                {
                    "score": 100,
                    "user": "player1",
                    "you": 0
                },
                {
                    "score": 90,
                    "user": "player2",
                    "you": 1
                },
                {
                    "score": 80,
                    "user": "player3",
                    "you": 0
                }
            ]
        }
    }
    """

    static let apiMessageSuccessJSON = """
    {
        "data": {
            "message": "Score recorded successfully",
            "success": 1
        }
    }
    """

    static let apiMessageCustomJSON = """
    {
        "data": {
            "message": "New high score!",
            "success": 1
        }
    }
    """

    static let emptyLeaderboardJSON = """
    {
        "data": {
            "leaderboard": []
        }
    }
    """
}
