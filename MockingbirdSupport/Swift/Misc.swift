public protocol AnyObject {}

// swiftlint:disable type_name
public typealias `class` = AnyObject
// swiftlint:enable type_name

public typealias AnyClass = AnyObject.Type

public protocol CustomStringConvertible {
    var description: String { get }
}

public protocol CustomDebugStringConvertible {
    var debugDescription: String { get }
}
