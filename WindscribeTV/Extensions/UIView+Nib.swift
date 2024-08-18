//
//  UIView+Nib.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 02/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

extension UIView {
    class func fromNib<T: UIView>() -> T {
        guard let view = Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as? T else {
            fatalError("Tried creating view of type \(String(describing: T.self)) and failed")
        }
        return view
    }
}
