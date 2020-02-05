import XCTest
import HTTPMock

class StubEntryTests: XCTestCase {
    var request: URLRequest!
    
    override func setUp() {
        request = URLRequest(url: URL(fileURLWithPath: "/"))
    }
    
    override func tearDown() {
        
    }
    
    func test_responseAsset_hasStream_hasETag() {
        // Given
        
        // When
        let sut = StubEntry(predicate: .alwaysTrue) { (_) in
            return HTTPResponseAsset(data: Data())
        }
        let asset = sut.responseAsset(for: request)
        
        // Then
        XCTAssertNotNil(asset.headerFields[HTTPHeaderName.eTag])
    }
    
    func test_responseAsset_noStream_noETag() {
        // Given
        
        // When
        let sut = StubEntry(predicate: .alwaysTrue) { (_) in
            return HTTPResponseAsset()
        }
        let asset = sut.responseAsset(for: request)
        
        // Then
        XCTAssertNil(asset.headerFields[HTTPHeaderName.eTag])
    }
}
