import AuthenticationServices
import Foundation
enum SignInResult {
    case success(ASAuthorizationAppleIDCredential)
    case failure(Error)
    case noCredentinals
}
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let completion: (SignInResult) -> Void

    init(completion: @escaping (SignInResult) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(appleIDCredential))
        } else {
            completion(.noCredentinals)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}
