import XCTest
import HTTPMock

class DataInputStreamGeneratorTests: XCTestCase {
    func test_streamLength() {
        // Given
        let data = "hello world - data".data(using: .utf8)!
        
        // When
        let sut = DataInputStreamGenerator(data: data)
        
        // Then
        XCTAssertEqual(sut.streamLength, data.count)
    }
    
    func test_makeStream() {
        // Given
        let data = "hello world - data".data(using: .utf8)!
        
        // When
        let sut = DataInputStreamGenerator(data: data)
        let streamData = sut.makeStream().readAllData()
        
        // Then
        XCTAssertEqual(streamData, data)
    }
}

class FileInputStreamGeneratorTests: XCTestCase {
    var data: Data!
    var fileURL: URL!
    
    override func setUp() {
        let fm = FileManager.default
        data = "hello world - file".data(using: .utf8)!
        fileURL = fm.temporaryDirectory.appendingPathComponent("stub_test")
        try? fm.removeItem(at: fileURL)
        try? data.write(to: fileURL)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        data = nil
        fileURL = nil
    }
    
    func test_streamLength() {
        // Given
        
        // When
        let sut = FileInputStreamGenerator(fileURL: fileURL)
        
        // Then
        XCTAssertEqual(sut.streamLength, data.count)
    }
    
    func test_makeStream() throws {
        // Given
        
        // When
        let sut = FileInputStreamGenerator(fileURL: fileURL)
        let streamData = try sut.makeStream().readAllData()
        
        // Then
        XCTAssertEqual(streamData, data)
    }
    
    func test_makeStream_whenInvalidFileURL_throwError() {
        // Given
        let url = URL(fileURLWithPath: "/hello/world/wow")
        
        // When
        let sut = FileInputStreamGenerator(fileURL: url)
        
        // Then
        XCTAssertThrowsError(try sut.makeStream())
    }
}
