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
    static func fromAsciiBase64(_ base64String: String, font: UIFont = .monospacedSystemFont(ofSize: 22, weight: .regular), padding: CGFloat = 20) -> UIImage? {
        guard let asciiData = Data(base64Encoded: base64String),
              let asciiString = String(data: asciiData, encoding: .utf8) else {
            return nil
        }

        // Break into lines
        let lines = asciiString.components(separatedBy: .newlines)

        // Determine max line width (in characters)
        let maxLineWidth = lines.map { $0.count }.max() ?? 0
        let lineHeight = font.lineHeight

        // Estimate image size
        let imageSize = CGSize(
            width: CGFloat(maxLineWidth) * font.pointSize * 0.6 + 2 * padding,
            height: CGFloat(lines.count) * lineHeight + 2 * padding
        )

        let renderer = UIGraphicsImageRenderer(size: imageSize)

        let image = renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: imageSize))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]

            for (i, line) in lines.enumerated() {
                let point = CGPoint(x: padding, y: padding + CGFloat(i) * lineHeight)
                line.draw(at: point, withAttributes: attributes)
            }
        }

        return image
    }

    static func fromBase64(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64),
              let image = UIImage(data: data) else { return nil }
        return image
    }
}
