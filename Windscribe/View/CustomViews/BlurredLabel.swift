//
//  BlurredLabel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 03/04/23.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import UIKit

class BlurredLabel: UILabel {
    var topInset: CGFloat = 5.0
    var bottomInset: CGFloat = 5.0
    var leftInset: CGFloat = 5.0
    var rightInset: CGFloat = 5.0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }

    var isBlurring = false {
        didSet {
            setNeedsDisplay()
        }
    }

    var blurRadius: Double = 10 {
        didSet {
            blurFilter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
        }
    }

    lazy var blurFilter: CIFilter? = {
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setDefaults()
        blurFilter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
        return blurFilter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.isOpaque = false
        layer.needsDisplayOnBoundsChange = true
        layer.contentsScale = UIScreen.main.scale
        layer.contentsGravity = .center
        isOpaque = false
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func display(_ layer: CALayer) {
        let bounds = layer.bounds
        guard !bounds.isEmpty && bounds.size.width < CGFloat(UINT16_MAX) else {
            layer.contents = nil
            return
        }
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.isOpaque, layer.contentsScale)
        if let ctx = UIGraphicsGetCurrentContext() {
            self.layer.draw(in: ctx)

            var image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
            if isBlurring, let cgImage = image {
                blurFilter?.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
                let ciContext = CIContext(cgContext: ctx, options: nil)
                if let blurOutputImage = blurFilter?.outputImage,
                   let cgImage = ciContext.createCGImage(blurOutputImage, from: blurOutputImage.extent)
                {
                    image = cgImage
                }
            }
            layer.contents = image
        }
        UIGraphicsEndImageContext()
    }
}
