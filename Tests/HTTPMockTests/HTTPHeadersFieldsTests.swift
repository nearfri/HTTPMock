import XCTest
import HTTPMock

class HTTPHeadersFieldsTests: XCTestCase {
    let headers: [String: String] = [
        "Connection": "close",
        "Proxy-Connection": "close",
        "Via": "HTTP/1.1 localhost (IBM-PROXY-WTE)",
        "Date": "Mon, 11 Mar 2019 03:47:29 GMT",
        "Server": "Apache/2.2.15 (Red Hat)",
        "Strict-Transport-Security": "max-age=15768000; includeSubDomains",
        "Last-Modified": "Mon, 11 Mar 2019 03:39:21 GMT",
        "Accept-Ranges": "bytes",
        "Content-Length": "6197",
        "Content-Type": "text/html; charset=UTF-8"
    ]
    
    var headerArray: [(name: String, value: String)] = []
    
    override func setUp() {
        headerArray = headers.map({ ($0.key, $0.value) })
    }
    
    override func tearDown() {
        
    }
    
    func test_initWithElements() {
        // Given
        
        // When
        let sut = HTTPHeaderFields(headerArray)
        
        // Then
        for (name, value) in headers {
            XCTAssertEqual(sut[name], value)
        }
    }
    
    func test_initWithElements_duplicateName_remainLast() {
        // Given
        let elements: [(String, String)] = [
            ("Content-Type", "text"),
            ("Content-Type", "jpg"),
            ("Content-Type", "json")
        ]
        
        // When
        let sut = HTTPHeaderFields(elements)
        
        // Then
        XCTAssertEqual(sut["Content-Type"], "json")
    }
    
    func test_subscript() {
        // Given
        var sut = HTTPHeaderFields()
        
        // When
        for (name, value) in headers {
            sut[name] = value
        }
        
        // Then
        for (name, value) in headers {
            XCTAssertEqual(sut[name], value)
        }
    }
    
    func test_subscript_caseInsensitiveCompare() {
        // Given
        let sut = HTTPHeaderFields(headerArray)
        
        // When
        let connection = sut["connection"]
        let proxyConnection = sut["proxy-connection"]
        let acceptRanges = sut["ACCEPT-RANGES"]
        
        // Then
        XCTAssertEqual(connection, "close")
        XCTAssertEqual(proxyConnection, "close")
        XCTAssertEqual(acceptRanges, "bytes")
    }
    
    func test_subscriptWithPosition() {
        // Given
        let sut = HTTPHeaderFields(headerArray)
        
        // When
        let position = sut.firstIndex(where: { (name, _) -> Bool in
            return name == "Accept-Ranges"
        })!
        let (name, value) = sut[position]
        
        // Then
        XCTAssertEqual(name, "Accept-Ranges")
        XCTAssertEqual(value, "bytes")
    }
    
    func test_operatorEqual() {
        // Given
        let input1 = headerArray
        let input2 = headerArray.map({ ($0.name.lowercased(), $0.value) })
        let input3 = headerArray.map({ ($0.value, $0.name) })
        let input4 = headerArray.dropFirst()
        
        // When
        let headers1 = HTTPHeaderFields(input1)
        let headers2 = HTTPHeaderFields(input2)
        let headers3 = HTTPHeaderFields(input3)
        let headers4 = HTTPHeaderFields(Array(input4))
        
        // Then
        XCTAssert(headers1 == headers2)
        XCTAssert(headers1 != headers3)
        XCTAssert(headers1 != headers4)
    }
    
    func test_initWithDictionary() {
        // Given
        let headers1 = HTTPHeaderFields(headerArray)
        
        // When
        let headers2 = HTTPHeaderFields(headers)
        
        // Then
        XCTAssert(headers2 == headers1)
    }
    
    func test_dictionary() {
        // Given
        let sut = HTTPHeaderFields(headerArray)
        
        // When
        let dictionary = sut.dictionary
        
        // Then
        XCTAssertEqual(dictionary, headers)
    }
}
