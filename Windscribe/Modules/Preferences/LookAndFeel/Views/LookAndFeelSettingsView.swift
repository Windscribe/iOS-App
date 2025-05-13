//
//  LookAndFeelSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct LookAndFeelSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: LookAndFeelSettingsViewModelImpl

    init(viewModel: any LookAndFeelSettingsViewModel) {
        guard let model = viewModel as? LookAndFeelSettingsViewModelImpl else {
            fatalError("ReferForDataSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)

            Text("Look And Feel Settings")
                .font(.title)
                .foregroundColor(.white)
        }
        .navigationTitle("Look And Feel")
        .navigationBarTitleDisplayMode(.inline)
    }
}
