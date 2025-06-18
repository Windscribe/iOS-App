//
//  SsoManager.swift
//  Windscribe
//
//  Created by Ginder Singh on 2025-05-28.
//  Copyright © 2025 Windscribe. All rights reserved.
//
import AuthenticationServices
import Combine
import RxSwift

protocol SSOManaging {
    func getSession() -> AnyPublisher<Session, Errors>
    func signOut()
}

class SSOManager: NSObject, ObservableObject, SSOManaging {
    private let logger: FileLogger
    private let apiManager: APIManager
    private var cancellables = Set<AnyCancellable>()
    private var ssoSession: PassthroughSubject<Session, Errors>?

    init(logger: FileLogger, apiManager: APIManager) {
        self.logger = logger
        self.apiManager = apiManager
    }

    /// Requests apple OAuth sign in token
    /// Uses token to get updated user session.
    func getSession() -> AnyPublisher<Session, Errors> {
        let subject = PassthroughSubject<Session, Errors>()
        ssoSession = subject

        let request = ASAuthorizationAppleIDProvider().createRequest().then {
            $0.requestedScopes = [.fullName, .email]
        }

        let controller = ASAuthorizationController(authorizationRequests: [request]).then {
            $0.delegate = self
            $0.presentationContextProvider = self
        }

        logger.logI("SSOManager", "Requesting apple indentity token.")
        controller.performRequests()

        return subject
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.ssoSession = nil
            })
            .eraseToAnyPublisher()
    }

    func signOut() {
        logger.logI("SSOManager", "Signing out user.")
        cancellables.removeAll()
        ssoSession = nil
    }
}

extension SSOManager: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            logger.logE("SSOManager", "Apple identity token is missing.")
            ssoSession?.send(completion: .failure(Errors.appleSsoError("Failed to obtain Apple identity token.")))
            return
        }

        logger.logI("SSOManager", "Requesting sso session for token")

        apiManager.ssoSession(token: token)
            .flatMap { ssoSession -> Single<Session> in
                self.apiManager.getSession(sessionAuth: ssoSession.sessionAuth)
                    .map { session in
                        // Get session from "\GET" will not have session auth set.
                        session.sessionAuthHash = ssoSession.sessionAuth
                        return session
                    }
            }
            .asPublisher()
            .sink(receiveCompletion: { completion in
                guard case .failure(let error) = completion,
                      let typedError = error as? Errors else {
                    return
                }

                self.ssoSession?.send(completion: .failure(typedError))
            },
            receiveValue: { session in
                self.ssoSession?.send(session)
                self.ssoSession?.send(completion: .finished)
            })
            .store(in: &cancellables)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        logger.logE("SSOManager", "Failed to get apple identity token: \(error.localizedDescription)")

        // Cancel Login
        if error is ASAuthorizationError {
            if let authorizationError = error as? ASAuthorizationError {
                if authorizationError.code == .canceled {
                    ssoSession?.send(completion: .failure(Errors.appleSsoError(TextsAsset.Authentication.appleLoginCanceled)))
                    return
                }
            }
        }

        // Unsuccessful Login
        ssoSession?.send(completion: .failure(Errors.appleSsoError("Unable to obtain Apple identity token.")))
    }
}

extension SSOManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first(
            where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {

            logger.logE("SSOManager", "No active window scene found.")
            assertionFailure("No active window scene found.")
            return UIWindow()
        }

        return window
    }
}
