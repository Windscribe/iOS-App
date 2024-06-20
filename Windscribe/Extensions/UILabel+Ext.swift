//
//  UILabel+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UILabel {

    func setLetterSpacing(value: CGFloat) {
        guard let labelText = text  else { return }
        let attributedString: NSMutableAttributedString
        if let labelAttributedText = attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        attributedString.addAttribute(NSAttributedString.Key.kern, value: value, range: NSRange(location: 0, length: attributedString.length))
        attributedText = attributedString
    }

    func blur() {
        let blurRadius = 5.1
        UIGraphicsBeginImageContext(bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setDefaults()
        let imageToBlur = CIImage(cgImage: (image?.cgImage)!)
        blurFilter?.setValue(imageToBlur, forKey: kCIInputImageKey)
        blurFilter?.setValue(blurRadius, forKey: "inputRadius")
        let outputImage: CIImage? = blurFilter?.outputImage
        let context = CIContext(options: nil)
        let cgimg = context.createCGImage(outputImage!, from: (outputImage?.extent)!)
        layer.contents = cgimg!
    }

    var numberOfVisibleLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight
        let text = (self.text ?? "") as NSString
        let textSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font as Any], context: nil)
        let lines = textSize.width/charSize/charSize
        let rounded = ceil(round(lines))
        return Int(rounded)
    }

    func setTextWithOffSet(text: String, offsetPercentage: Double = 30.0) {
        let offset = (font.ascender - font.capHeight) * (offsetPercentage / 100.0)
        attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font as Any, NSAttributedString.Key.baselineOffset: offset])
    }

    func setTextWithOffSet(text: NSAttributedString?, offsetPercentage: Double = 30.0) {
        guard let text = text else { return }
        let offset = (font.ascender - font.capHeight) * (offsetPercentage / 100.0)
        let existingAttributes = NSMutableAttributedString(attributedString: text)
        existingAttributes.addAttributes([NSAttributedString.Key.font: font as Any, NSAttributedString.Key.baselineOffset: offset], range: NSRange.init(location: 0, length: text.length))
        attributedText = existingAttributes
    }
}
