import Foundation

// `curl <url> -i --http1.1 -o <file_name>`으로 저장한 파일 데이터를 로딩한다.
// `--http1.1` 옵션없이 저장하면 start line이 `HTTP/2`로 시작하는 경우가 있는데
// CFHTTPMessage는 `HTTP/2.0`은 파싱할 수 있어도 `HTTP/2`는 파싱할 수 없으므로 `--http1.1` 옵션을 추가해줘야 한다.
public struct HTTPResponse {
    public var statusCode: Int = 500
    public var headerFields: [String: String] = [:]
    public var bodyData: Data = Data()
    
    public init(data: Data) throws {
        let message = CFHTTPMessageCreateEmpty(nil, false).takeRetainedValue()
        
        try data.withUnsafeBytes({ (bytes: UnsafeRawBufferPointer) in
            guard let ptr = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                CFHTTPMessageAppendBytes(message, ptr, data.count)
                else { throw Error.invalidResponseData }
        })
        
        guard CFHTTPMessageIsHeaderComplete(message) else {
            throw Error.headerIsNotCompleted
        }
        
        guard let headerFields = CFHTTPMessageCopyAllHeaderFields(message)?.takeRetainedValue()
            else { throw Error.copyHeaderFieldsFailed }
        let statusCode = CFHTTPMessageGetResponseStatusCode(message)
        let bodyData = CFHTTPMessageCopyBody(message)?.takeRetainedValue() as Data?
        
        self.statusCode = statusCode
        self.headerFields = (headerFields as? [String: String]) ?? [:]
        self.bodyData = bodyData ?? Data()
    }
}

extension HTTPResponse {
    public enum Error: Swift.Error {
        case invalidResponseData
        case headerIsNotCompleted
        case copyHeaderFieldsFailed
    }
}
