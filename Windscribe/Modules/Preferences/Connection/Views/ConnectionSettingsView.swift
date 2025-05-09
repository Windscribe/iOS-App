//
//  ConnectionSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ConnectionSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ConnectionSettingsViewModelImpl

    init(viewModel: any ConnectionSettingsViewModel) {
        guard let model = viewModel as? ConnectionSettingsViewModelImpl else {
            fatalError("ConnectionSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.lightMidnight
                .edgesIgnoringSafeArea(.all)

            Text("Connection Settings")
                .font(.title)
                .foregroundColor(.white)
        }
    }
}
