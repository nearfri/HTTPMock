import Foundation

public enum HTTPMethod: Equatable {
    case GET
    case HEAD
    case POST
    case PUT
    case PATCH
    case DELETE
    case RAW(value: String)
}

extension HTTPMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .RAW(value: value)
    }
}

extension HTTPMethod: RawRepresentable {
    public init(rawValue: String) {
        self = .RAW(value: rawValue)
    }
    
    public var rawValue: String {
        switch self {
        case .GET:      return "GET"
        case .HEAD:     return "HEAD"
        case .POST:     return "POST"
        case .PUT:      return "PUT"
        case .PATCH:    return "PATCH"
        case .DELETE:   return "DELETE"
        case .RAW(let value):   return value
        }
    }
}

extension HTTPMethod: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}
