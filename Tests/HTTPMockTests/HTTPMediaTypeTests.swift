import XCTest
import HTTPMock

class HTTPMediaTypeTests: XCTestCase {
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    func test_initWithPathExtension() {
        // Given
        
        // When
        let sut = HTTPMediaType(pathExtension: "js")
        
        // Then
        XCTAssertEqual(sut, HTTPMediaType.javascript)
    }
}
