import XCTest
import HTTPMock

class StubRegistryTests: XCTestCase {
    let sut: StubRegistry = StubRegistry.shared
    let predicate = HTTPRequestPredicate.alwaysTrue
    let data = "hello world".data(using: .utf8)!
    let request = URLRequest(url: URL(fileURLWithPath: "/"))
    
    override func setUp() {
        
    }
    
    override func tearDown() {
        sut.unregisterAllEntries()
    }
    
    func test_stubWithAssetProvider() {
        // Given
        let data = self.data
        
        // When
        stub(when: predicate, then: { _ in HTTPResponseAsset(data: data) })
        let stubEntry = sut.entry(for: request)
        
        // Then
        XCTAssertEqual(stubEntry?.predicate.description, predicate.description)
    }
    
    func test_stubWithAssetBuilder() {
        // Given
        
        // When
        stub(when: predicate, then: .data(data))
        let stubEntry = sut.entry(for: request)
        
        // Then
        XCTAssertEqual(stubEntry?.predicate.description, predicate.description)
    }
    
    func test_unregisterEntry() {
        // Given
        let entry = stub(when: predicate, then: .data(data))
        
        // When
        sut.unregister(entry)
        
        // Then
        XCTAssertNil(sut.entry(for: request))
    }
}
