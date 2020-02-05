import Foundation

public class StubEntry {
    public let id: String = UUID().uuidString
    public let predicate: HTTPRequestPredicate
    private let assetProvider: (URLRequest) -> HTTPResponseAsset
    
    public init(predicate: HTTPRequestPredicate,
                assetProvider: @escaping (URLRequest) -> HTTPResponseAsset) {
        self.predicate = predicate
        self.assetProvider = assetProvider
    }
    
    public func responds(to request: URLRequest) -> Bool {
        return predicate.evaluate(request)
    }
    
    public func responseAsset(for request: URLRequest) -> HTTPResponseAsset {
        var result = assetProvider(request)
        if result.bodyStreamGenerator != nil && result.headerFields[HTTPHeaderName.eTag] == nil {
            result.headerFields[HTTPHeaderName.eTag] = "\"\(id)\""
        }
        return result
    }
}
