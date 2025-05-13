//
//  RobertSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct RobertSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: RobertSettingsViewModelImpl

    init(viewModel: any RobertSettingsViewModel) {
        guard let model = viewModel as? RobertSettingsViewModelImpl else {
            fatalError("RobertSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)

            Text("Robert Settings")
                .font(.title)
                .foregroundColor(.white)
        }
        .navigationTitle("R.O.B.E.R.T")
        .navigationBarTitleDisplayMode(.inline)
    }
}
