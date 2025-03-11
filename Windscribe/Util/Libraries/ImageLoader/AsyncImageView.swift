//
//  AsyncImageView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit

/// A `UIImageView` subclass that loads images asynchronously while displaying a loading indicator
class AsyncImageView: UIImageView {

    /// The image loader instance for fetching images
    private var imageLoader: ImageLoader?

    private let activityIndicator = UIActivityIndicatorView(style: .large).then {
        $0.isHidden = true
    }

    /// Placeholder image shown when loading or if the request fails
    private let placeholder: UIImage?

    /// Initializes an `AsyncImageView` with a URL and placeholder
    /// - Parameters:
    ///   - urlString: The URL string of the image.
    ///   - placeholder: A fallback image displayed while loading or on failure
    init(urlString: String? = nil, placeholder: UIImage? = nil) {
        self.placeholder = placeholder
        super.init(frame: .zero)

        self.image = placeholder

        guard let urlString else { return }

        self.imageLoader = ImageLoader(urlString: urlString)

        setupLoadingIndicator()
        loadImage()
    }

    required init?(coder: NSCoder) {
        self.placeholder = nil
        super.init(coder: coder)

        setupLoadingIndicator()
    }

    private func setupLoadingIndicator() {
        activityIndicator.do {
            $0.isHidden = false
            $0.color = .white
            $0.hidesWhenStopped = true
        }
        addSubview(activityIndicator)

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    /// Loads the image asynchronously and applies a fade-in animation
    private func loadImage() {
        activityIndicator.startAnimating()

        imageLoader?.startLoading { [weak self] image in
            guard let self = self else { return }

            if let newImage = image {
                UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self.image = newImage
                })
            } else {
                self.image = self.placeholder
            }

            self.activityIndicator.stopAnimating()
        }
    }
}
