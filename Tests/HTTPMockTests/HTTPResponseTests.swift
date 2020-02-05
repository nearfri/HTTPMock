import XCTest
import HTTPMock

class HTTPResponseTests: XCTestCase {
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    func test_init_hasValidState() throws {
        // Given
        let responseFileURL = url(forResource: "swift.org.response")
        let responseData = try Data(contentsOf: responseFileURL)
        
        // When
        let sut = try HTTPResponse(data: responseData)
        
        // Then
        XCTAssertEqual(sut.statusCode, 200)
        XCTAssertEqual(sut.bodyData.count, 6197)
        XCTAssertEqual(sut.headerFields[HTTPHeaderName.contentLength], "6197")
    }
}
