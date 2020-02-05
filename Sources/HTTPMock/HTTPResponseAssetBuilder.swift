import Foundation

public struct HTTPResponseAssetBuilder {
    public private(set) var asset: HTTPResponseAsset
    
    private init(asset: HTTPResponseAsset) {
        self.asset = asset
    }
}

public extension HTTPResponseAssetBuilder {
    static func error(_ error: Error) -> HTTPResponseAssetBuilder {
        return HTTPResponseAssetBuilder(asset: HTTPResponseAsset(error: error))
    }
    
    static func data(_ data: Data, contentType: HTTPMediaType) -> HTTPResponseAssetBuilder {
        return self.data(data)
            .settingHeaderField(name: HTTPHeaderName.contentType, value: contentType.rawValue)
    }
    
    // 위의 메소드에서 contentType을 Optional로 하면 코딩 시 자동완성이 안되기 때문에 아래와 같은 별도의 메소드가 필요함
    static func data(_ data: Data) -> HTTPResponseAssetBuilder {
        return HTTPResponseAssetBuilder(asset: HTTPResponseAsset(data: data))
    }
    
    static func fileURL(_ fileURL: URL) -> HTTPResponseAssetBuilder {
        return HTTPResponseAssetBuilder(asset: HTTPResponseAsset(fileURL: fileURL))
    }
    
    static func httpResponse(_ httpResponse: HTTPResponse) -> HTTPResponseAssetBuilder {
        return HTTPResponseAssetBuilder(asset: HTTPResponseAsset(httpResponse: httpResponse))
    }
    
    func settingStatusCode(_ statusCode: Int) -> HTTPResponseAssetBuilder {
        var result = self
        result.asset.statusCode = statusCode
        return result
    }
    
    func settingHeaderField(name: String, value: String?) -> HTTPResponseAssetBuilder {
        var result = self
        result.asset.headerFields[name] = value
        return result
    }
    
    func settingContentType(_ contentType: HTTPMediaType) -> HTTPResponseAssetBuilder {
        return settingHeaderField(name: HTTPHeaderName.contentType, value: contentType.rawValue)
    }
    
    func settingResponseDelay(_ responseDelay: TimeInterval) -> HTTPResponseAssetBuilder {
        var result = self
        result.asset.responseDelay = responseDelay
        return result
    }
    
    func settingPreferredBytesPerSecond(_ bytesPerSecond: Int) -> HTTPResponseAssetBuilder {
        var result = self
        result.asset.preferredBytesPerSecond = bytesPerSecond
        return result
    }
}
