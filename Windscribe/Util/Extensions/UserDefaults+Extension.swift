//
//  UserDefaults+Extension.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-09-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine

extension UserDefaults {
    func publisher<T>(for key: String, type: T.Type) -> AnyPublisher<T?, Never> {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: self)
            .map { _ in self.object(forKey: key) as? T }
            .prepend(self.object(forKey: key) as? T)
            .eraseToAnyPublisher()
    }
}
