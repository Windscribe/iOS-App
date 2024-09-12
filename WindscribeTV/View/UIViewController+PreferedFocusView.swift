//
//  PreferredFocusedViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 11/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class PreferredFocusedViewController: UIViewController {
    var myPreferredFocusedView: UIView?
    
    override var preferredFocusedView: UIView? {
        return myPreferredFocusedView
    }
}
