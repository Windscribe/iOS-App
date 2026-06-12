//
//  PreferencesContentView..swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/05/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

struct PreferencesContentView<Entry: MenuEntryHeaderType>: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    let entries: [Entry]
    let entrySelected: (_ entry: Entry, _ action: MenuEntryActionResponseType) -> Void

    var body: some View {
        BaseContentView {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(entries, id: \.id) { entry in
                        MenuEntryView(item: entry, action: { actionType in
                            entrySelected(entry, actionType)
                        })
                    }
                }
                .padding(.top, 8)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
    }
}
