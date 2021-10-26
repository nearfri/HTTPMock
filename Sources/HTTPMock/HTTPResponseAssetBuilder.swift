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
    
    static func data(_ data: Data, contentType: HTTPMediaType? = nil) -> HTTPResponseAssetBuilder {
        let builder = HTTPResponseAssetBuilder(asset: HTTPResponseAsset(data: data))
        guard let contentType = contentType else {
            return builder
        }
        return builder.settingHeaderField(name: HTTPHeaderName.contentType,
                                          value: contentType.rawValue)
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
