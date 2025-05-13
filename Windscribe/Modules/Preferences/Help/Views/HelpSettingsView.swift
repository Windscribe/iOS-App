//
//  HelpSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct HelpSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: HelpSettingsViewModelImpl

    init(viewModel: any HelpSettingsViewModel) {
        guard let model = viewModel as? HelpSettingsViewModelImpl else {
            fatalError("HelpSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)

            Text("Help Settings")
                .font(.title)
                .foregroundColor(.white)
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}
