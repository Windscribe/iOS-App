//
//  ImageCache.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

/// Defines an interface for caching images in memory
protocol ImageCaching: AnyObject {
    /// Retrieves an image from the cache
    /// - Parameter key: The URL string used as a cache key
    /// - Returns: A `UIImage` if found in cache, otherwise `nil`
    func getCachedImage(for key: String) -> UIImage?

    /// Stores an image in the cache
    /// - Parameters:
    ///   - image: The image to cache
    ///   - key: The URL string used as a cache key
    func cacheImage(_ image: UIImage, for key: String)
}

/// A lightweight memory cache for storing images using `NSCache`
class ImageCache: ImageCaching {

    static let shared = ImageCache(maxLimit: 5)

    private let cache = NSCache<NSString, UIImage>()

    /// Initializes the cache with a configurable size limit
    /// - Parameter maxLimit: The maximum number of images to store in memory
    init(maxLimit: Int) {
        cache.countLimit = maxLimit
    }

    /// Retrieves a cached image for a given key
    func getCachedImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    /// Caches an image in memory
    func cacheImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    /// Updates the maximum cache size
    /// - Parameter maxLimit: The new cache limit
    static func setCacheLimit(_ maxLimit: Int) {
        shared.cache.countLimit = maxLimit
    }
}
