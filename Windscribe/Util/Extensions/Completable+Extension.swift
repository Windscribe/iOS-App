import RxSwift

extension Completable {
    func await(with disposeBag: DisposeBag) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.subscribe(
                onCompleted: {
                    continuation.resume()
                },
                onError: { error in
                    continuation.resume(throwing: error)
                }
            ).disposed(by: disposeBag)
        }
    }
}
