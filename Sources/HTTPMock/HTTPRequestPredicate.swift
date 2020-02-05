import Foundation

public struct HTTPRequestPredicate: CustomStringConvertible {
    public let description: String
    public let evaluate: (URLRequest) -> Bool
}

public extension HTTPRequestPredicate {
    static var alwaysTrue: HTTPRequestPredicate {
        return HTTPRequestPredicate(description: "TRUE", evaluate: { _ in true })
    }
    
    static var alwaysFalse: HTTPRequestPredicate {
        return HTTPRequestPredicate(description: "FALSE", evaluate: { _ in false })
    }
    
    static func || (lhs: HTTPRequestPredicate, rhs: HTTPRequestPredicate) -> HTTPRequestPredicate {
        return HTTPRequestPredicate(
            description: "(\(lhs.description) OR \(rhs.description))",
            evaluate: { (request) in lhs.evaluate(request) || rhs.evaluate(request) }
        )
    }
    
    static func && (lhs: HTTPRequestPredicate, rhs: HTTPRequestPredicate) -> HTTPRequestPredicate {
        return HTTPRequestPredicate(
            description: "(\(lhs.description) AND \(rhs.description))",
            evaluate: { (request) in lhs.evaluate(request) && rhs.evaluate(request) }
        )
    }
    
    static prefix func ! (predicate: HTTPRequestPredicate) -> HTTPRequestPredicate {
        return HTTPRequestPredicate(
            description: "NOT (\(predicate.description))",
            evaluate: { (request) in !predicate.evaluate(request) }
        )
    }
}

public extension HTTPRequestPredicate {
    static func isHTTPMethod(_ method: HTTPMethod) -> HTTPRequestPredicate {
        return HTTPRequestPredicate(
            description: "HTTPMethod is \(method)",
            evaluate: { (request) in request.httpMethod == method.rawValue }
        )
    }
}

public extension HTTPRequestPredicate {
    static func hasHeaderField(name: String) -> HTTPRequestPredicate {
        return HTTPRequestPredicate(
            description: "header has \(name)",
            evaluate: { (request) in request.value(forHTTPHeaderField: name) != nil }
        )
    }
    
    static func hasHeaderField(name: String, value: String) -> HTTPRequestPredicate {
        return HTTPRequestPredicate(
            description: "\(name) header is \(value)",
            evaluate: { (request) in request.value(forHTTPHeaderField: name) == value }
        )
    }
}

public extension HTTPRequestPredicate {
    static func matchesURL(description: String,
                           evaluate: @escaping (URL) -> Bool) -> HTTPRequestPredicate {
        return HTTPRequestPredicate(
            description: description,
            evaluate: { (request) in request.url.map({ evaluate($0) }) ?? false }
        )
    }
    
    static func isURL(_ url: URL) -> HTTPRequestPredicate {
        return matchesURL(
            description: "URL is \(url)",
            evaluate: { $0 == url }
        )
    }
    
    static func isURLString(_ urlString: String) -> HTTPRequestPredicate {
        return matchesURL(
            description: "URL is \(urlString)",
            evaluate: { (url) in url.absoluteString == urlString }
        )
    }
    
    static func isHost(_ host: String) -> HTTPRequestPredicate {
        return matchesURL(
            description: "host is \(host)",
            evaluate: { (url) in url.host == host }
        )
    }
    
    static func isPath(_ path: String) -> HTTPRequestPredicate {
        return matchesURL(
            description: "path is \(path)",
            evaluate: { (url) in url.path == path }
        )
    }
    
    static func hasPathPrefix(_ pathPrefix: String) -> HTTPRequestPredicate {
        return matchesURL(
            description: "path has prefix \(pathPrefix)",
            evaluate: { (url) in url.path.hasPrefix(pathPrefix) }
        )
    }
    
    static func hasPathSuffix(_ pathSuffix: String) -> HTTPRequestPredicate {
        return matchesURL(
            description: "path has suffix \(pathSuffix)",
            evaluate: { (url) in url.path.hasSuffix(pathSuffix) }
        )
    }
    
    static func hasPathExtension(_ pathExtension: String) -> HTTPRequestPredicate {
        return matchesURL(
            description: "path has extension \(pathExtension)",
            evaluate: { (url) in url.pathExtension == pathExtension }
        )
    }
    
    static func hasLastPathComponent(_ lastPathComponent: String) -> HTTPRequestPredicate {
        return matchesURL(
            description: "path has lastComponent \(lastPathComponent)",
            evaluate: { (url) in url.lastPathComponent == lastPathComponent }
        )
    }
    
    static func containsQueryItems(_ queryItems: [URLQueryItem]) -> HTTPRequestPredicate {
        return matchesURL(
            description: "queryItems contains \(queryItems)",
            evaluate: { (url) in
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                    let queries = components.queryItems
                    else { return false }
                return queryItems.allSatisfy({ queries.contains($0) })
        })
    }
}
