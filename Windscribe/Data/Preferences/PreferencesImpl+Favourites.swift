//
//  Preferences+Favourites.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-09-08.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

extension PreferencesImpl {
    func observeFavouriteIds() -> AnyPublisher<[String], Never> {
        guard let sharedDefault = sharedDefault else {
            return Just([]).eraseToAnyPublisher()
        }

        return NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: sharedDefault)
            .compactMap { _ in sharedDefault.stringArray(forKey: SharedKeys.tvFavourites) }
            .prepend(sharedDefault.stringArray(forKey: SharedKeys.tvFavourites))
            .map { $0 ?? [] }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func addFavouriteId(_ id: String) {
        var currentIds = sharedDefault?.stringArray(forKey: SharedKeys.tvFavourites) ?? []
        if !currentIds.contains(id) {
            currentIds.append(id)
            sharedDefault?.set(currentIds, forKey: SharedKeys.tvFavourites)
        }
    }

    func removeFavouriteId(_ id: String) {
        var currentIds = sharedDefault?.stringArray(forKey: SharedKeys.tvFavourites) ?? []
        if let index = currentIds.firstIndex(of: id) {
            currentIds.remove(at: index)
            sharedDefault?.set(currentIds, forKey: SharedKeys.tvFavourites)
        }
    }

    func clearFavourites() {
        sharedDefault?.removeObject(forKey: SharedKeys.tvFavourites)
    }
}
