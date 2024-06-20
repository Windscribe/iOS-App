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
            return "Connection Failure!".localize()
        case .change:
            return "Change Protocol".localize()
        }
    }

    func getDescription() -> String {
        switch self {
        case .failure:
            return "The protocol you’ve chosen has failed to connect. Windscribe will attempt to reconnect using the first protocol below.".localize()
        case .change:
            return "Quickly re-connect using a different protocol. ".localize()
        }
    }
}

typealias ProtocolPort = (protocolName: String, portName: String)
class DisplayProtocolPort {
    var protocolPort: ProtocolPort
    var viewType: ProtocolViewType

    init(protocolPort: ProtocolPort, viewType: ProtocolViewType) {
        self.protocolPort = protocolPort
        self.viewType = viewType
    }
}
