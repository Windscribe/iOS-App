//
//  Preferences+Favourites.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-09-08.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
extension SharedSecretDefaults {
    
    func observeFavouriteIds() -> Observable<[String]> {
        return sharedDefault?.rx
            .observe([String].self, SharedKeys.tvFavourites)
            .map { $0 ?? [] }
            .startWith(sharedDefault?.stringArray(forKey: SharedKeys.tvFavourites) ?? [])
            .asObservable() ?? Observable.empty()
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
}
