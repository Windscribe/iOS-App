//
//  Router.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 25/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

protocol RootRouter {
    func routeTo(to: RouteID, from: UIViewController)
}
