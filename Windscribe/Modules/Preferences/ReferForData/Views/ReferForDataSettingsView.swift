//
//  ReferForDataSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ReferForDataSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ReferForDataSettingsViewModelImpl

    init(viewModel: any ReferForDataSettingsViewModel) {
        guard let model = viewModel as? ReferForDataSettingsViewModelImpl else {
            fatalError("ReferForDataSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.lightMidnight
                .edgesIgnoringSafeArea(.all)

            Text("Refer For Data Settings")
                .font(.title)
                .foregroundColor(.white)
        }
    }
}
