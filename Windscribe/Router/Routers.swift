//
//  Routers.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-13.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

protocol NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController)
}

protocol RootRouter {
    func routeTo(to: RouteID, from: WSUIViewController)
}
