//
//  SendTicketViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol SendTicketViewModel: ObservableObject { }

final class SendTicketViewModelImpl: SendTicketViewModel {
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger) {
        self.logger = logger

        bind()
    }

    func bind() {
        // TODO: Bind
    }
}
