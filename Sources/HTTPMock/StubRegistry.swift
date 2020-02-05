import Foundation

@discardableResult
public func stub(when predicate: HTTPRequestPredicate,
                 then assetProvider: @escaping (URLRequest) -> HTTPResponseAsset) -> StubEntry {
    return StubRegistry.shared.registerEntry(for: predicate, assetProvider: assetProvider)
}

@discardableResult
public func stub(when predicate: HTTPRequestPredicate,
                 then assetBuilder: HTTPResponseAssetBuilder) -> StubEntry {
    return StubRegistry.shared.registerEntry(for: predicate, assetBuilder: assetBuilder)
}

public class StubRegistry {
    public static let shared: StubRegistry = StubRegistry()
    
    private var entries: [StubEntry] = []
    private let syncQueue: DispatchQueue = {
        return DispatchQueue(label: "com.nearfri.HTTPMock.StubRegistry", attributes: .concurrent)
    }()
    
    private init() {}
    
    public func register(_ entry: StubEntry) {
        syncQueue.async(flags: .barrier) {
            self.entries.append(entry)
        }
    }
    
    @discardableResult
    public func registerEntry(
        for predicate: HTTPRequestPredicate,
        assetProvider: @escaping (URLRequest) -> HTTPResponseAsset
    ) -> StubEntry {
        let entry = StubEntry(predicate: predicate, assetProvider: assetProvider)
        register(entry)
        return entry
    }
    
    public func unregister(_ entry: StubEntry) {
        syncQueue.async(flags: .barrier) {
            self.entries.removeAll(where: { $0 === entry })
        }
    }
    
    public func unregisterAllEntries() {
        syncQueue.async(flags: .barrier) {
            self.entries.removeAll()
        }
    }
    
    public func entry(for request: URLRequest) -> StubEntry? {
        return syncQueue.sync(execute: {
            return entries.last(where: { $0.responds(to: request) })
        })
    }
}

public extension StubRegistry {
    @discardableResult
    func registerEntry(for predicate: HTTPRequestPredicate,
                       assetBuilder: HTTPResponseAssetBuilder) -> StubEntry {
        return registerEntry(for: predicate, assetProvider: { _ in assetBuilder.asset })
    }
}
