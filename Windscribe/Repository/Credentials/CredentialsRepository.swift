//
//  CredentialsRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol CredentialsRepository {
    func getUpdatedOpenVPNCrendentials() -> Single<OpenVPNServerCredentials?>
    func getUpdatedIKEv2Crendentials() -> Single<IKEv2ServerCredentials?>
    func getUpdatedServerConfig() -> Single<String>
    func selectedServerCredentialsType() -> ServerCredentials.Type
}
