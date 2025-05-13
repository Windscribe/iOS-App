//
//  GeneralSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct GeneralSettingsView: View {
    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)

            Text("General")
                .font(.title)
                .foregroundColor(.white)
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
    }
}
