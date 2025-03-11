//
//  Then.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-01-31.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import UIKit.UIGeometry

public protocol Then {}

extension Then where Self: Any {

  /// Makes it available to set properties with closures just after initializing and copying the value types
  @inlinable
  public func with(_ block: (inout Self) throws -> Void) rethrows -> Self {
    var copy = self
    try block(&copy)
    return copy
  }

  /// Makes it available to execute something with closures.
  @inlinable
  public func `do`(_ block: (Self) throws -> Void) rethrows {
    try block(self)
  }

}

extension Then where Self: AnyObject {

  /// Makes it available to set properties with closures just after initializing
  @inlinable
  public func then(_ block: (Self) throws -> Void) rethrows -> Self {
    try block(self)
    return self
  }

}

extension NSObject: Then {}
extension Array: Then {}
extension Dictionary: Then {}
extension Set: Then {}
extension JSONDecoder: Then {}
extension JSONEncoder: Then {}
extension UIEdgeInsets: Then {}
extension UIOffset: Then {}
extension UIRectEdge: Then {}
