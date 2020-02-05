import XCTest
import HTTPMock

class URLProtocolServiceTests: XCTestCase {
    override func setUp() {
        
    }
    
    override func tearDown() {
        URLProtocolService.unregisterStubFromSharedSession()
        URLProtocolService.unregisterStubFromDefaultConfiguration()
        URLProtocolService.unregisterStubFromEphemeralConfiguration()
    }
    
    func test_registerStubInSharedSession() {
        // Given
        let url = URL(string: "https://localhost")!
        let stubData = "hello world".data(using: .utf8)!
        stub(when: .isHost(url.host!), then: .data(stubData))
        
        // When
        URLProtocolService.registerStubInSharedSession()
        let downloadedData = try? downloadData(url, using: URLSession.shared)
        
        // Then
        XCTAssertEqual(downloadedData, stubData)
    }
    
    func test_unregisterStubFromSharedSession() {
        // Given
        let url = URL(string: "https://localhost")!
        let stubData = "hello world".data(using: .utf8)!
        stub(when: .isHost(url.host!), then: .data(stubData))
        
        URLProtocolService.registerStubInSharedSession()
        
        // When
        URLProtocolService.unregisterStubFromSharedSession()
        let downloadedData = try? downloadData(url, using: URLSession.shared)
        
        // Then
        XCTAssertNil(downloadedData)
    }
    
    func test_registerStubInDefaultConfiguration() {
        // Given
        
        // When
        URLProtocolService.registerStubInDefaultConfiguration()
        let protocolClasses = URLSessionConfiguration.default.protocolClasses ?? []
        
        // Then
        XCTAssert(protocolClasses.contains(where: { $0 == URLProtocolStub.self }))
    }
    
    func test_unregisterStubFromDefaultConfiguration() {
        // Given
        URLProtocolService.registerStubInDefaultConfiguration()
        
        // When
        URLProtocolService.unregisterStubFromDefaultConfiguration()
        let protocolClasses = URLSessionConfiguration.default.protocolClasses ?? []
        
        // Then
        XCTAssertFalse(protocolClasses.contains(where: { $0 == URLProtocolStub.self }))
    }
    
    func test_registerStubInEphemeralConfiguration() {
        // Given
        
        // When
        URLProtocolService.registerStubInEphemeralConfiguration()
        let protocolClasses = URLSessionConfiguration.ephemeral.protocolClasses ?? []
        
        // Then
        XCTAssert(protocolClasses.contains(where: { $0 == URLProtocolStub.self }))
    }
    
    func test_unregisterStubFromEphemeralConfiguration() {
        // Given
        URLProtocolService.registerStubInEphemeralConfiguration()
        
        // When
        URLProtocolService.unregisterStubFromEphemeralConfiguration()
        let protocolClasses = URLSessionConfiguration.ephemeral.protocolClasses ?? []
        
        // Then
        XCTAssertFalse(protocolClasses.contains(where: { $0 == URLProtocolStub.self }))
    }
    
    func test_registerStubInConfiguration() {
        // Given
        let configuration = URLSessionConfiguration.default
        
        // When
        URLProtocolService.registerStub(in: configuration)
        let protocolClasses = configuration.protocolClasses ?? []
        
        // Then
        XCTAssert(protocolClasses.contains(where: { $0 == URLProtocolStub.self }))
    }
    
    func test_unregisterStubFromConfiguration() {
        // Given
        let configuration = URLSessionConfiguration.default
        URLProtocolService.registerStub(in: configuration)
        
        // When
        URLProtocolService.unregisterStub(from: configuration)
        let protocolClasses = configuration.protocolClasses ?? []
        
        // Then
        XCTAssertFalse(protocolClasses.contains(where: { $0 == URLProtocolStub.self }))
    }
}
