//
//  RobertyFiltersRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 12/01/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum RobertFilterErrors: Error {
    case failedSync(message: String)
    case failedUpdate(message: String)
}

protocol RobertyFiltersRepository {
    // Subjects
    var robertFilters: CurrentValueSubject<[RobertFilterModel], Never> { get }

    // update funcs
    func refreshFilters() async throws

    func updateFilter(_ filter: RobertFilterModel) async throws

}

class RobertyFiltersRepositoryImpl: RobertyFiltersRepository {
    var robertFilters = CurrentValueSubject<[RobertFilterModel], Never>([])

    private let logger: FileLogger
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase

    init(logger: FileLogger,
         apiManager: APIManager,
         localDatabase: LocalDatabase) {
        self.logger = logger
        self.apiManager = apiManager
        self.localDatabase = localDatabase

        loadFilters()
    }

    private func loadFilters() {
        robertFilters.send(localDatabase.getRobertFilters() ?? [])
    }

    func refreshFilters() async throws {
        do {
            let apiFilters = try await apiManager.getRobertFilters()
            let filterModels = Array(apiFilters.filters.map { $0.getModel() })
            localDatabase.saveRobertFilters(filters: filterModels)
            robertFilters.send(filterModels)
        } catch {
            if robertFilters.value.isEmpty {
                loadFilters()
            }
        }
    }

    func updateFilter(_ filter: RobertFilterModel) async throws {
        do {
            let filterId = filter.id
            let status: Int32 = filter.enabled ? 0 : 1
            _ = try await apiManager.updateRobertSettings(id: filterId, status: status)

            // Sync Robert filters after successful update
            do {
                _ = try await apiManager.syncRobertFilters()

                localDatabase.toggleRobertRule(id: filterId)
                loadFilters()
            } catch {
                if let error = error as? Errors {
                    var newError = ""
                    switch error {
                    case let .apiError(e):
                        newError = e.errorMessage ?? "Failed to sync Robert Settings."
                    default:
                        newError = "Failed to sync Robert Settings. \(error.description)"
                    }
                    self.logger.logE("RobertyFiltersRepository", newError)
                    throw RobertFilterErrors.failedSync(message: newError)
                } else {
                    // Rethrow non-Errors type errors (e.g., RobertFilterErrors)
                    throw error
                }
            }
        } catch {
            if let error = error as? Errors {
                var newError = ""
                switch error {
                case let .apiError(e):
                    newError = e.errorMessage ?? TextsAsset.Robert.failedToGetFilters
                default:
                    newError = "\(TextsAsset.Robert.failedToGetFilters) \(error.description)"
                }
                self.logger.logE("RobertyFiltersRepository", newError)
                throw RobertFilterErrors.failedSync(message: newError)
            } else {
                // Rethrow non-Errors type errors (e.g., RobertFilterErrors from inner catch)
                throw error
            }
        }
    }
}
