import Foundation

public struct HTTPMediaType: RawRepresentable, Equatable {
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init?(pathExtension: String) {
        guard let mediaType = HTTPMediaType.mediaTypesByFileExtension[pathExtension] else {
            return nil
        }
        self = mediaType
    }
}

extension HTTPMediaType: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension HTTPMediaType: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

public extension HTTPMediaType {
    static let javascript: HTTPMediaType = "application/javascript"
    static let json: HTTPMediaType = "application/json"
    static let urlEncodedForm: HTTPMediaType = "application/x-www-form-urlencoded"
    static let xml: HTTPMediaType = "application/xml"
    static let zip: HTTPMediaType = "application/zip"
    static let gzip: HTTPMediaType = "application/x-gzip"
    static let tar: HTTPMediaType = "application/x-tar"
    static let pdf: HTTPMediaType = "application/pdf"
    static let binary: HTTPMediaType = "application/octet-stream"
    static let mp3: HTTPMediaType = "audio/mpeg"
    static let ogg: HTTPMediaType = "audio/ogg"
    static let avi: HTTPMediaType = "video/avi"
    static let mpeg: HTTPMediaType = "video/mpeg"
    static let mp4: HTTPMediaType = "video/mp4"
    static let quicktime: HTTPMediaType = "video/quicktime"
    static let png: HTTPMediaType = "image/png"
    static let jpeg: HTTPMediaType = "image/jpeg"
    static let gif: HTTPMediaType = "image/gif"
    static let tiff: HTTPMediaType = "image/tiff"
    static let svg: HTTPMediaType = "image/svg+xml"
    static let plainText: HTTPMediaType = "text/plain"
    static let css: HTTPMediaType = "text/css"
    static let html: HTTPMediaType = "text/html"
    static let csv: HTTPMediaType = "text/csv"
}

extension HTTPMediaType {
    private static let mediaTypesByFileExtension: [String: HTTPMediaType] = [
        "js": .javascript,
        "json": .json,
        "xml": .xml,
        "zip": .zip,
        "tar": .tar,
        "pdf": .pdf,
        "bin": .binary,
        "mp3": .mp3,
        "ogg": .ogg,
        "avi": .avi,
        "mpeg": .mpeg,
        "mpg": .mpeg,
        "mp4": .mp4,
        "mov": .quicktime,
        "png": .png,
        "jpeg": .jpeg,
        "jpg": .jpeg,
        "gif": .gif,
        "tiff": .tiff,
        "tif": .tiff,
        "svg": .svg,
        "svgz": .svg,
        "txt": .plainText,
        "text": .plainText,
        "srt": .plainText,
        "css": .css,
        "html": .html,
        "htm": .html,
        "shtml": .html,
        "csv": .csv
    ]
}
