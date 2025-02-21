//
//  ImageLoader.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

/// Handles asynchronous image loading from a URL
class ImageLoader {

    private let urlString: String

    init(urlString: String) {
        self.urlString = urlString
    }

    /// Starts loading an image asynchronously
    /// - Parameter completion: A closure that returns the downloaded image or `nil` if failed
    func startLoading(completion: @escaping (UIImage?) -> Void) {
        // First, check if the image is already cached
        if let cachedImage = ImageCache.shared.getCachedImage(for: urlString) {
            completion(cachedImage) // Return cached image immediately
            return
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        // Fetch the image using URLSession (runs asynchronously)
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            ImageCache.shared.cacheImage(image, for: self.urlString)

            DispatchQueue.main.async {
                completion(image)
            }
        }

        task.resume()
    }
}
