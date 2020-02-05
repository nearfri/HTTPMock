import XCTest
import HTTPMock

class URLProtocolStubTests: XCTestCase {
    var session: URLSession!
    var imageURL: URL!
    var imageData: Data!
    
    override func setUp() {
        URLProtocolService.registerStubInSharedSession()
        
        session = URLSession.shared
        imageURL = url(forResource: "apple-devices.jpg")
        imageData = try! Data(contentsOf: imageURL)
    }
    
    override func tearDown() {
        URLProtocolService.unregisterStubFromSharedSession()
        StubRegistry.shared.unregisterAllEntries()
    }
    
    func test_dataTask() {
        // Given
        let url = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"), then: .fileURL(imageURL))
        
        // When
        let downloadedData = try? downloadData(url, using: session)
        
        // Then
        XCTAssertEqual(downloadedData, imageData)
    }
    
    func test_dataTask_noMatch_noStub() {
        // Given
        let url = URL(string: "https://nononosite.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"), then: .fileURL(imageURL))
        
        // When
        let downloadedData = try? downloadData(url, using: session)
        
        // Then
        XCTAssertNil(downloadedData)
    }
    
    func test_redirect() {
        // Given
        let redirectURL = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"), then: .fileURL(imageURL))
        
        let url = URL(string: "https://nononosite.com/images/apple-devices.jpg")!
        stub(
            when: .isHost("nononosite.com"),
            then: HTTPResponseAssetBuilder
                .data(Data())
                .settingStatusCode(301)
                .settingHeaderField(name: HTTPHeaderName.location,
                                    value: redirectURL.absoluteString)
        )
        
        // When
        let downloadedData = try? downloadData(url, using: session)
        
        // Then
        XCTAssertEqual(downloadedData, imageData)
    }
    
    func test_responseDelay() {
        // Given
        let data = Data(count: 100)
        let url = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"),
             then: HTTPResponseAssetBuilder
                .data(data)
                .settingResponseDelay(0.1))
        
        // When
        let start = Date()
        let downloadedData = try? downloadData(url, using: session, timeout: 5)
        let duration = -start.timeIntervalSinceNow
        
        // Then
        XCTAssertGreaterThan(duration, 0.1)
        XCTAssertEqual(downloadedData, data)
    }
    
    func test_preferredBytesPerSecond() {
        // Given
        let url = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"),
             then: HTTPResponseAssetBuilder
                .fileURL(imageURL)
                .settingPreferredBytesPerSecond(1_300_000 * 2))
        
        // When
        let start = Date()
        let downloadedData = try? downloadData(url, using: session, timeout: 5)
        let duration = -start.timeIntervalSinceNow
        
        // Then
        XCTAssertGreaterThan(duration, 0.5)
        XCTAssertEqual(downloadedData, imageData)
    }
    
    func test_suspend() {
        // Given
        let url = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"), then: .fileURL(imageURL))
        
        let completionCalled = Atomic(false)
        let task = session.dataTask(with: url) { (_, _, _)  in
            completionCalled.mutate { $0 = true }
        }
        task.resume()
        
        // When
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        task.suspend()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
        
        // Then
        XCTAssertFalse(completionCalled.value)
    }
    
    func test_resume_afterSuspend() {
        // Given
        let url = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"), then: .fileURL(imageURL))
        
        let completionCalled = Atomic(false)
        let expectation = self.expectation(description: #function)
        let task = session.dataTask(with: url) { (_, _, _)  in
            completionCalled.mutate { $0 = true }
            expectation.fulfill()
        }
        task.resume()
        
        // When
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        task.suspend()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        task.resume()
        waitForExpectations(timeout: 1.0)
        
        // Then
        XCTAssert(completionCalled.value)
    }
    
    func test_cancel() {
        // Given
        let url = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"), then: .fileURL(imageURL))
        
        let error: Atomic<NSError?> = Atomic(nil)
        let expectation = self.expectation(description: #function)
        let task = session.dataTask(with: url) { (_, _, err)  in
            error.mutate { $0 = err as NSError? }
            expectation.fulfill()
        }
        task.resume()
        
        // When
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        task.cancel()
        waitForExpectations(timeout: 1.0)
        
        // Then
        XCTAssertEqual(error.value?.code, NSURLErrorCancelled)
    }
    
    func test_resume_afterCancel() {
        // Given
        let url = URL(string: "https://server.com/images/apple-devices.jpg")!
        stub(when: .isHost("server.com"),
             then: HTTPResponseAssetBuilder
                .fileURL(imageURL)
                .settingPreferredBytesPerSecond(5_000_000))
        
        let task = session.downloadTask(with: url) { (url, response, err) in
            
        }
        task.resume()
        
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        let resumeDataWrapper: Atomic<Data?> = Atomic(nil)
        let resumeExpectation = self.expectation(description: "Resume data")
        task.cancel(byProducingResumeData: { (data) in
            resumeDataWrapper.mutate { $0 = data }
            resumeExpectation.fulfill()
        })
        waitForExpectations(timeout: 1.0)
        
        guard let resumeData = resumeDataWrapper.value else {
            XCTFail("Failed to produce resume data")
            return
        }
        
        // When
        let downloadedData: Atomic<Data?> = Atomic(nil)
        let downloadExpectation = self.expectation(description: "Download data")
        let resumeTask = session.downloadTask(withResumeData: resumeData) { (tempURL, _, _) in
            downloadedData.mutate { $0 = tempURL.flatMap({ try? Data(contentsOf: $0) }) }
            downloadExpectation.fulfill()
        }
        resumeTask.resume()
        waitForExpectations(timeout: 2.0)
        
        // Then
        // 1 바이트도 받지 못한 상태에서 cancel(byProducingResumeData:)을 하게 되면 resume data는 있지만
        // resume file이 없다. 이런 경우 이어받기를 시작하면 에러와 함께 다운로드에 실패한다.
        // 이것은 stub 보다는 URLSession의 버그인 것 같다.
        XCTAssertEqual(downloadedData.value, imageData)
    }
}
