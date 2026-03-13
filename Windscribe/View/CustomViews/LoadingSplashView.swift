//
//  LoadingSplashView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-26.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ImageIO
import UIKit

class LoadingSplashView: UIView {
    var logoView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        logoView = UIImageView(frame: CGRect(x: self.frame.width / 2 - 40, y: self.frame.height / 2 - 40, width: 80, height: 80))

        // Show the same static logo as the launch screen until the GIF is decoded, gives us a better smoke and mirrors
        // bridge between the bootscreen and the splash so there is less of a jarring blip
        logoView.image = UIImage(named: "logo-login")
        logoView.contentMode = .scaleAspectFit

        addSubview(logoView)

        // Decode GIF frames off the main thread, then animate via Core Animation
        decodeAndAnimateLogo()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - GPU-composited logo animation

    private func decodeAndAnimateLogo() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard
                let url = Bundle.main.url(forResource: "ws-rotating-logo", withExtension: "gif"),
                let data = try? Data(contentsOf: url),
                let source = CGImageSourceCreateWithData(data as CFData, nil)
            else { return }

            let count = CGImageSourceGetCount(source)
            guard count > 0 else { return }

            var frames = [CGImage]()
            var keyTimes = [NSNumber]()
            var totalDuration: Double = 0

            // Extract frames and per-frame delays
            for i in 0 ..< count {
                guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
                frames.append(cgImage)

                let delay = LoadingSplashView.frameDelay(at: i, source: source)
                totalDuration += delay
            }

            guard !frames.isEmpty, totalDuration > 0 else { return }

            // Build normalized key times (0.0 ... 1.0)
            var accumulated: Double = 0
            for i in 0 ..< frames.count {
                keyTimes.append(NSNumber(value: accumulated / totalDuration))
                let delay = LoadingSplashView.frameDelay(at: i, source: source)
                accumulated += delay
            }
            keyTimes.append(1.0) // final key time

            DispatchQueue.main.async {
                guard let self = self else { return }

                // Create a new image view for the animated GIF on top of the static logo
                let animatedView = UIImageView(frame: self.logoView.frame)
                animatedView.alpha = 0
                animatedView.layer.contents = frames[0]
                self.insertSubview(animatedView, aboveSubview: self.logoView)

                let animation = CAKeyframeAnimation(keyPath: "contents")
                animation.values = frames
                animation.keyTimes = keyTimes
                animation.duration = totalDuration
                animation.repeatCount = .infinity
                animation.calculationMode = .discrete
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                animatedView.layer.add(animation, forKey: "logoSpin")

                // Crossfade from static logo to animated GIF
                UIView.animate(withDuration: 0.1) {
                    animatedView.alpha = 1
                    self.logoView.alpha = 0
                } completion: { _ in
                    self.logoView.removeFromSuperview()
                    self.logoView = animatedView
                }
            }
        }
    }

    /// Read the GIF frame delay for a given index, with a 25ms floor.
    private static func frameDelay(at index: Int, source: CGImageSource) -> Double {
        var delay = 0.025
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifDict = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else { return delay }

        if let unclamped = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0 {
            delay = unclamped
        } else if let clamped = gifDict[kCGImagePropertyGIFDelayTime] as? Double, clamped > 0 {
            delay = clamped
        }

        return max(delay, 0.025)
    }
}
