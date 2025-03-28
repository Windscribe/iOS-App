//
//  RouterModifier.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct RouterInjectionModifier<Router: ObservableObject>: ViewModifier {
    @ObservedObject var router: Router

    func body(content: Content) -> some View {
        content.environmentObject(router)
    }
}

extension View {
    func withRouter<Router: ObservableObject>(_ router: Router) -> some View {
        self.modifier(RouterInjectionModifier(router: router))
    }
}
