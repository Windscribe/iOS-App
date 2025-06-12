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

typealias ProtocolPort = (protocolName: String, portName: String)
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
