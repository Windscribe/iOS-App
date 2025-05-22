//
//  UIImage+Ext.swift
//  Windscribe
//
//  Created by Bushra Sagir on 16/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

public extension UIImage {
    class func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context!.setFillColor(color.cgColor)
        context!.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
}

extension UIImage {
    static func fromBase64(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64),
              let image = UIImage(data: data) else { return nil }
        return image
    }
}
