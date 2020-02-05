import XCTest
import HTTPMock

class HTTPResponseAssetBuilderTests: XCTestCase {
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    func test_error() {
        // Given
        let error = NSError(domain: NSCocoaErrorDomain,
                            code: CocoaError.fileNoSuchFile.rawValue,
                            userInfo: nil)
        
        // When
        let sut = HTTPResponseAssetBuilder.error(error)
        let assetError = sut.asset.error as NSError?
        
        // Then
        XCTAssertEqual(assetError, error)
    }
    
    func test_dataWithContentType() {
        // Given
        let contentType = HTTPMediaType.json
        
        // When
        let sut = HTTPResponseAssetBuilder.data(Data(), contentType: contentType)
        let headerFields = sut.asset.headerFields
        
        // Then
        XCTAssertEqual(headerFields[HTTPHeaderName.contentType], contentType.rawValue)
    }
    
    func test_data() throws {
        // Given
        let data = "hello world - data".data(using: .utf8)!
        
        // When
        let sut = HTTPResponseAssetBuilder.data(data)
        
        // Then
        XCTAssertNotNil(sut.asset.bodyStreamGenerator)
    }
    
    func test_fileURL() throws {
        // Given
        let fm = FileManager.default
        let data = "hello world - file".data(using: .utf8)!
        let fileURL = fm.temporaryDirectory.appendingPathComponent("stub_test")
        try? fm.removeItem(at: fileURL)
        try data.write(to: fileURL)
        
        // When
        let sut = HTTPResponseAssetBuilder.fileURL(fileURL)
        
        // Then
        XCTAssertNotNil(sut.asset.bodyStreamGenerator)
    }
    
    func test_httpResponse() throws {
        // Given
        let responseFileURL = url(forResource: "swift.org.response")
        let responseData = try Data(contentsOf: responseFileURL)
        let response = try HTTPResponse(data: responseData)
        
        // When
        let sut = HTTPResponseAssetBuilder.httpResponse(response)
        let asset = sut.asset
        
        // Then
        XCTAssertNotNil(asset.bodyStreamGenerator)
    }
    
    func test_settingStatusCode() {
        // Given
        let data = "hello world - setting".data(using: .utf8)!
        var sut = HTTPResponseAssetBuilder.data(data)
        
        // When
        sut = sut.settingStatusCode(206)
        
        // Then
        XCTAssertEqual(sut.asset.statusCode, 206)
    }
    
    func test_settingHeaderField() {
        // Given
        let data = "hello world - setting".data(using: .utf8)!
        var sut = HTTPResponseAssetBuilder.data(data)
        
        // When
        sut = sut.settingHeaderField(name: "myKey", value: "myValue")
        
        // Then
        XCTAssertEqual(sut.asset.headerFields["myKey"], "myValue")
    }
    
    func test_settingContentType() {
        // Given
        let data = "hello world - setting".data(using: .utf8)!
        var sut = HTTPResponseAssetBuilder.data(data)
        
        // When
        sut = sut.settingContentType(.mp4)
        
        // Then
        XCTAssertEqual(sut.asset.headerFields[HTTPHeaderName.contentType],
                       HTTPMediaType.mp4.rawValue)
    }
    
    func test_settingResponseDelay() {
        // Given
        let data = "hello world - setting".data(using: .utf8)!
        var sut = HTTPResponseAssetBuilder.data(data)
        
        // When
        sut = sut.settingResponseDelay(15.0)
        
        // Then
        XCTAssertEqual(sut.asset.responseDelay, 15.0)
    }
    
    func test_settingPreferredBytesPerSecond() {
        // Given
        let data = "hello world - setting".data(using: .utf8)!
        var sut = HTTPResponseAssetBuilder.data(data)
        
        // When
        sut = sut.settingPreferredBytesPerSecond(23)
        
        // Then
        XCTAssertEqual(sut.asset.preferredBytesPerSecond, 23)
    }
}
