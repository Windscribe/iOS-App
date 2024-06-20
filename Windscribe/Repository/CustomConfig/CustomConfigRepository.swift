//
//  CustomConfigRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-26.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol CustomConfigRepository {
    func saveWgConfig(url: URL) -> RepositoryError?
    func removeWgConfig(fileId: String)
    func saveOpenVPNConfig(url: URL) -> RepositoryError?
    func removeOpenVPNConfig(fileId: String)
}
