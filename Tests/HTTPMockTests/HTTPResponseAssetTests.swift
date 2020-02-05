import XCTest
import HTTPMock

class HTTPResponseAssetTests: XCTestCase {
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    func test_init_setDefaultHeaderFields() {
        // Given
        let streamGenerator = DataInputStreamGenerator(data: Data())
        
        // When
        let sut = HTTPResponseAsset(bodyStreamGenerator: streamGenerator)
        
        // Then
        XCTAssertNotNil(sut.headerFields[HTTPHeaderName.acceptRanges])
        XCTAssertNotNil(sut.headerFields[HTTPHeaderName.contentLength])
    }
    
    func test_redirectURL() {
        // Given
        let redirectURL = URL(string: "https://www.apple.com")!
        let headerFields: HTTPHeaderFields = [HTTPHeaderName.location: redirectURL.absoluteString]
        
        // When
        let sut = HTTPResponseAsset(statusCode: 301, headerFields: headerFields)
        
        // Then
        XCTAssertEqual(sut.redirectURL, redirectURL)
    }
    
    func test_initWithData() {
        // Given
        let data = "hello world - data".data(using: .utf8)!
        
        // When
        let sut = HTTPResponseAsset(data: data)
        
        // Then
        XCTAssertNotNil(sut.bodyStreamGenerator)
    }
    
    func test_initWithFileURL() throws {
        // Given
        let fm = FileManager.default
        let data = "hello world - file".data(using: .utf8)!
        let fileURL = fm.temporaryDirectory.appendingPathComponent("stub_test.txt")
        try? fm.removeItem(at: fileURL)
        try data.write(to: fileURL)
        
        // When
        let sut = HTTPResponseAsset(fileURL: fileURL)
        
        // Then
        XCTAssertNotNil(sut.bodyStreamGenerator)
        XCTAssertEqual(sut.headerFields[HTTPHeaderName.contentType],
                       HTTPMediaType.plainText.rawValue)
    }
    
    func test_initWithHTTPResponse() throws {
        // Given
        let responseFileURL = url(forResource: "swift.org.response")
        let responseData = try Data(contentsOf: responseFileURL)
        let response = try HTTPResponse(data: responseData)
        
        // When
        let sut = HTTPResponseAsset(httpResponse: response)
        
        // Then
        XCTAssertNotNil(sut.bodyStreamGenerator)
        XCTAssertEqual(sut.headerFields["Via"], "HTTP/1.1 localhost (IBM-PROXY-WTE)")
        XCTAssertEqual(sut.headerFields[HTTPHeaderName.contentType], "text/html; charset=UTF-8")
    }
}
