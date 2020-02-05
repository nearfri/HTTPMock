import Foundation

public enum HTTPHeaderName {}

public extension HTTPHeaderName {
    static let accept = "Accept"
    static let acceptRanges = "Accept-Ranges"
    static let contentEncoding = "Content-Encoding"
    static let contentLanguage = "Content-Language"
    static let contentLength = "Content-Length"
    static let contentRange = "Content-Range"
    static let contentType = "Content-Type"
    static let eTag = "ETag"
    static let expires = "Expires"
    static let ifMatch = "If-Match"
    static let ifModifiedSince = "If-Modified-Since"
    static let ifRange = "If-Range"
    static let ifUnmodifiedSince = "If-Unmodified-Since"
    static let keepAlive = "Keep-Alive"
    static let location = "Location"
    static let range = "Range"
}
