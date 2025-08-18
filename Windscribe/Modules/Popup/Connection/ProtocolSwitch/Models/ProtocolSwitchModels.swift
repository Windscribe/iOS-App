//
//  Windscribe
//
//  Created by Thomas on 22/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

enum ProtocolFallbacksType {
    case failure
    case change

    func getIconAsset() -> String {
        switch self {
        case .failure:
            return ImagesAsset.windscribeWarning
        case .change:
            return ImagesAsset.windscribeReload
        }
    }

    func getHeader() -> String {
        switch self {
        case .failure:
            return TextsAsset.ProtocolVariation.connectionFailureTitle
        case .change:
            return TextsAsset.ProtocolVariation.protocolChangeTitle
        }
    }

    func getDescription() -> String {
        switch self {
        case .failure:
            return TextsAsset.ProtocolVariation.connectionFailureDescription
        case .change:
            return TextsAsset.ProtocolVariation.protocolChangeDescription
        }
    }
}

enum ProtocolViewType: Equatable {
    case connected
    case normal
    case fail
    case nextUp(countdown: Int)

    var isSelectable: Bool {
        switch self {
        case .fail: false
        default: true
        }
    }

    var showCountdown: Bool {
        switch self {
        case let .nextUp(countdown): countdown >= 0
        default: false
        }
    }

    var isNextup: Bool {
        switch self {
        case .nextUp: true
        default: false
        }
    }
}

typealias ProtocolPort = (protocolName: String, portName: String)

struct ProtocolDisplayItem: Identifiable {
    let id = UUID()
    let protocolName: String
    let portName: String
    let description: String
    let viewType: ProtocolViewType

    // Computed properties for UI display
    var displayName: String { protocolName }
    var protocolPort: ProtocolPort { (protocolName, portName) }
}

class DisplayProtocolPort: CustomStringConvertible {
    var protocolPort: ProtocolPort
    var viewType: ProtocolViewType

    init(protocolPort: ProtocolPort, viewType: ProtocolViewType) {
        self.protocolPort = protocolPort
        self.viewType = viewType
    }

    var description: String {
        return "\(protocolPort) \(viewType)"
    }
}

struct ProtocolViewDetails: Equatable {
    let protocolName: String
    let viewType: ProtocolViewType
}
