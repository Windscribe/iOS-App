import Foundation

public enum SocketResult {
    case success
    case failure(Error)

    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    public var isFailure: Bool {
        return !isSuccess
    }

    public var error: Error? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}
