import Foundation

public struct HTTPResponseAsset {
    public var statusCode: Int
    public var headerFields: HTTPHeaderFields
    public var bodyStreamGenerator: InputStreamGenerator?
    public var responseDelay: TimeInterval
    public var preferredBytesPerSecond: Int
    public var error: Error?
    
    /// Creates a HTTPResponseAsset from the given InputStream.
    public init(statusCode: Int = DefaultValue.statusCode,
                headerFields: HTTPHeaderFields = [:],
                bodyStreamGenerator: InputStreamGenerator? = nil,
                responseDelay: TimeInterval = DefaultValue.responseDelay,
                preferredBytesPerSecond: Int = DefaultValue.preferredBytesPerSecond,
                error: Error? = nil) {
        self.statusCode = statusCode
        self.headerFields = headerFields
        self.bodyStreamGenerator = bodyStreamGenerator
        self.responseDelay = responseDelay
        self.preferredBytesPerSecond = preferredBytesPerSecond
        self.error = error
        
        setupHeaderFields()
    }
    
    private mutating func setupHeaderFields() {
        guard let streamLength = bodyStreamGenerator?.streamLength else { return }
        
        headerFields = HTTPHeaderFieldsBuilder(headerFields: headerFields)
            .settingIfAbsent(name: HTTPHeaderName.acceptRanges, value: "bytes")
            .settingIfAbsent(name: HTTPHeaderName.contentLength, value: "\(streamLength)")
            .headerFields
    }
    
    public var redirectURL: URL? {
        guard (300..<400).contains(statusCode) else { return nil }
        return headerFields[HTTPHeaderName.location].flatMap({ URL(string: $0) })
    }
}

extension HTTPResponseAsset {
    public enum DefaultValue {
        public static let statusCode: Int = 200
        public static let responseDelay: TimeInterval = 0
        public static let preferredBytesPerSecond: Int = 100_000_000
    }
}

public extension HTTPResponseAsset {
    /// Creates a HTTPResponseAsset from the given Data.
    init(statusCode: Int = DefaultValue.statusCode,
         headerFields: HTTPHeaderFields = [:],
         data: Data,
         responseDelay: TimeInterval = DefaultValue.responseDelay,
         preferredBytesPerSecond: Int = DefaultValue.preferredBytesPerSecond) {
        
        self.init(statusCode: statusCode, headerFields: headerFields,
                  bodyStreamGenerator: DataInputStreamGenerator(data: data),
                  responseDelay: responseDelay,
                  preferredBytesPerSecond: preferredBytesPerSecond)
    }
    
    /// Creates a HTTPResponseAsset from the given URL.
    init(statusCode: Int = DefaultValue.statusCode,
         headerFields: HTTPHeaderFields = [:],
         fileURL: URL,
         responseDelay: TimeInterval = DefaultValue.responseDelay,
         preferredBytesPerSecond: Int = DefaultValue.preferredBytesPerSecond) {
        
        let headerBuilder = HTTPHeaderFieldsBuilder(headerFields: headerFields)
            .settingIfAbsent(name: HTTPHeaderName.contentType,
                             value: HTTPMediaType(pathExtension: fileURL.pathExtension)?.rawValue)
        
        self.init(statusCode: statusCode, headerFields: headerBuilder.headerFields,
                  bodyStreamGenerator: FileInputStreamGenerator(fileURL: fileURL),
                  responseDelay: responseDelay,
                  preferredBytesPerSecond: preferredBytesPerSecond)
    }
    
    /// Creates a HTTPResponseAsset from the given HTTPResponse.
    init(httpResponse: HTTPResponse,
         responseDelay: TimeInterval = DefaultValue.responseDelay,
         preferredBytesPerSecond: Int = DefaultValue.preferredBytesPerSecond) {
        
        self.init(statusCode: httpResponse.statusCode,
                  headerFields: HTTPHeaderFields(httpResponse.headerFields),
                  data: httpResponse.bodyData, responseDelay: responseDelay,
                  preferredBytesPerSecond: preferredBytesPerSecond)
    }
}

private struct HTTPHeaderFieldsBuilder {
    private(set) var headerFields: HTTPHeaderFields
    
    init(headerFields: HTTPHeaderFields) {
        self.headerFields = headerFields
    }
    
    func settingIfAbsent(
        name: String,
        value: @autoclosure () -> String?
    ) -> HTTPHeaderFieldsBuilder {
        var result = self
        if result.headerFields[name] == nil {
            result.headerFields[name] = value()
        }
        return result
    }
}
