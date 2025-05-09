//
//  AccountSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct AccountSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: AccountSettingsViewModelImpl

    init(viewModel: any AccountSettingsViewModel) {
        guard let model = viewModel as? AccountSettingsViewModelImpl else {
            fatalError("AccountSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.lightMidnight
                .edgesIgnoringSafeArea(.all)

            Text("Account Settings")
                .font(.title)
                .foregroundColor(.white)
        }
    }
}
