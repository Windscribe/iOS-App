//
//  SendTicketView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct SendTicketView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: SendTicketViewModelImpl

    init(viewModel: any SendTicketViewModel) {
        guard let model = viewModel as? SendTicketViewModelImpl else {
            fatalError("SendTicketView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)

            Text("Send Ticket")
                .font(.title)
                .foregroundColor(.white)
        }
        .dynamicTypeSize(dynamicTypeRange)
        .background(Color.nightBlue)
        .navigationTitle(TextsAsset.SubmitTicket.submitTicket)
        .navigationBarTitleDisplayMode(.inline)
    }
}
