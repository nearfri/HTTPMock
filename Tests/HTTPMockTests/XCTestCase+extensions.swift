import XCTest

extension XCTestCase {
    func url(forResource name: String) -> URL {
        let sourceFileURL = URL(fileURLWithPath: #file)
        let directoryURL = sourceFileURL.deletingLastPathComponent()
        let result = directoryURL.appendingPathComponent("Resources/\(name)")
        return result
    }
    
    func downloadData(_ url: URL,
                      using session: URLSession,
                      timeout: TimeInterval = 1,
                      description: String = #function) throws -> Data {
        let result: Atomic<Data?> = Atomic(nil)
        let error: Atomic<Error?> = Atomic(nil)

        let expectation = self.expectation(description: description)
        let task = session.dataTask(with: url) { (data, _, err) in
            result.mutate { $0 = data }
            error.mutate { $0 = err }
            expectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: timeout)

        switch (result.value, error.value) {
        case let (result?, _):
            return result
        case let (_, error?):
            throw error
        default:
            task.cancel()
            throw TestError.timeoutWhileWaiting
        }
    }
}

// Xcode 버그 때문에 에러를 직접 만들어야 한다.
// https://bugs.swift.org/browse/SR-11449
enum TestError: Error {
    case timeoutWhileWaiting
}
