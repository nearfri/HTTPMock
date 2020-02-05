import XCTest
import HTTPMock

class HTTPRequestPredicateTests: XCTestCase {
    var url: URL!
    var request: URLRequest!
    
    override func setUp() {
        url = URL(string: "https://apple.com/root/dir/file.txt?q1=v1&q2=v2")
        request = URLRequest(url: url)
    }
    
    override func tearDown() {
        
    }
    
    func test_alwaysTrue() {
        XCTAssertTrue(HTTPRequestPredicate.alwaysTrue.evaluate(request))
    }
    
    func test_alwaysFalse() {
        XCTAssertFalse(HTTPRequestPredicate.alwaysFalse.evaluate(request))
    }
    
    func test_operatorOR() {
        // Given
        
        // When
        let opFalseFalse: HTTPRequestPredicate = .alwaysFalse || .alwaysFalse
        let opFalseTrue: HTTPRequestPredicate = .alwaysFalse || .alwaysTrue
        let opTrueFalse: HTTPRequestPredicate = .alwaysTrue || .alwaysFalse
        let opTrueTrue: HTTPRequestPredicate = .alwaysTrue || .alwaysTrue
        
        // Then
        XCTAssertFalse(opFalseFalse.evaluate(request))
        XCTAssertTrue(opFalseTrue.evaluate(request))
        XCTAssertTrue(opTrueFalse.evaluate(request))
        XCTAssertTrue(opTrueTrue.evaluate(request))
    }
    
    func test_operatorAND() {
        // Given
        
        // When
        let opFalseFalse: HTTPRequestPredicate = .alwaysFalse && .alwaysFalse
        let opFalseTrue: HTTPRequestPredicate = .alwaysFalse && .alwaysTrue
        let opTrueFalse: HTTPRequestPredicate = .alwaysTrue && .alwaysFalse
        let opTrueTrue: HTTPRequestPredicate = .alwaysTrue && .alwaysTrue
        
        // Then
        XCTAssertFalse(opFalseFalse.evaluate(request))
        XCTAssertFalse(opFalseTrue.evaluate(request))
        XCTAssertFalse(opTrueFalse.evaluate(request))
        XCTAssertTrue(opTrueTrue.evaluate(request))
    }
    
    func test_operatorNOT() {
        // Given
        
        // When
        let opNotFalse: HTTPRequestPredicate = !.alwaysFalse
        let opNotTrue: HTTPRequestPredicate = !.alwaysTrue
        
        // Then
        XCTAssertTrue(opNotFalse.evaluate(request))
        XCTAssertFalse(opNotTrue.evaluate(request))
    }
    
    func test_isHTTPMethod() {
        // Given
        request.httpMethod = HTTPMethod.PATCH.rawValue
        
        // When
        let op = HTTPRequestPredicate.isHTTPMethod(.PATCH)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_hasHeaderFieldName() {
        // Given
        request.setValue("myValue", forHTTPHeaderField: "myHeader")
        
        // When
        let op = HTTPRequestPredicate.hasHeaderField(name: "myHeader")
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_hasHeaderFieldNameValue() {
        // Given
        request.setValue("myValue", forHTTPHeaderField: "myHeader")
        
        // When
        let op = HTTPRequestPredicate.hasHeaderField(name: "myHeader", value: "myValue")
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_isURL() {
        // Given
        
        // When
        let op = HTTPRequestPredicate.isURL(url)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_isURLString() {
        // Given
        let urlString = "https://apple.com/root/dir/file.txt?q1=v1&q2=v2"
        
        // When
        let op = HTTPRequestPredicate.isURLString(urlString)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_isHost() {
        // Given
        let host = "apple.com"
        
        // When
        let op = HTTPRequestPredicate.isHost(host)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_isPath() {
        // Given
        let path = "/root/dir/file.txt"
        
        // When
        let op = HTTPRequestPredicate.isPath(path)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_hasPathPrefix() {
        // Given
        let prefix = "/root/dir"
        
        // When
        let op = HTTPRequestPredicate.hasPathPrefix(prefix)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_hasPathSuffix() {
        // Given
        let suffix = "dir/file.txt"
        
        // When
        let op = HTTPRequestPredicate.hasPathSuffix(suffix)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_hasPathExtension() {
        // Given
        let ext = "txt"
        
        // When
        let op = HTTPRequestPredicate.hasPathExtension(ext)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_hasLastPathComponent() {
        // Given
        let lastPathComponent = "file.txt"
        
        // When
        let op = HTTPRequestPredicate.hasLastPathComponent(lastPathComponent)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_containsQueryItems_paramsAreEqual_true() {
        // Given
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q1", value: "v1"),
            URLQueryItem(name: "q2", value: "v2")
        ]
        
        // When
        let op = HTTPRequestPredicate.containsQueryItems(queryItems)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_containsQueryItems_paramsArePartial_true() {
        // Given
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q1", value: "v1")
        ]
        
        // When
        let op = HTTPRequestPredicate.containsQueryItems(queryItems)
        
        // Then
        XCTAssert(op.evaluate(request))
    }
    
    func test_containsQueryItems_paramsAreOvercharge_false() {
        // Given
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q1", value: "v1"),
            URLQueryItem(name: "q2", value: "v2"),
            URLQueryItem(name: "q3", value: "v3")
        ]
        
        // When
        let op = HTTPRequestPredicate.containsQueryItems(queryItems)
        
        // Then
        XCTAssertFalse(op.evaluate(request))
    }
}
