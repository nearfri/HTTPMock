import Foundation

public enum URLProtocolService {}

public extension URLProtocolService {
    static func registerStubInSharedSession() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func unregisterStubFromSharedSession() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }
    
    // URLProtocol.registerClass()는 shared session에만 적용되므로 default configuration에도 적용하고 싶다면
    // method swizzling을 해야 한다. http://stackoverflow.com/a/38560677/2419589
    static func registerStubInDefaultConfiguration() {
        URLSessionConfigurationSwizzler.isDefaultSwizzled = true
    }
    
    static func unregisterStubFromDefaultConfiguration() {
        URLSessionConfigurationSwizzler.isDefaultSwizzled = false
    }
    
    static func registerStubInEphemeralConfiguration() {
        URLSessionConfigurationSwizzler.isEphemeralSwizzled = true
    }
    
    static func unregisterStubFromEphemeralConfiguration() {
        URLSessionConfigurationSwizzler.isEphemeralSwizzled = false
    }
    
    static func registerStub(in configuration: URLSessionConfiguration) {
        let classes = configuration.protocolClasses ?? []
        if !classes.contains(where: { $0 == URLProtocolStub.self }) {
            configuration.protocolClasses = [URLProtocolStub.self] + classes
        }
    }
    
    static func unregisterStub(from configuration: URLSessionConfiguration) {
        guard var classes = configuration.protocolClasses else { return }
        classes.removeAll(where: { $0 == URLProtocolStub.self })
        configuration.protocolClasses = classes
    }
}

// MARK: -

private class URLSessionConfigurationSwizzler {
    private static let syncQueue: DispatchQueue = {
        return DispatchQueue(label: "com.nearfri.HTTPMock.URLSessionConfigurationSwizzler")
    }()
    
    static var isDefaultSwizzled: Bool {
        get { syncQueue.sync { defaultMethodItem.isSwizzled } }
        set { syncQueue.sync { defaultMethodItem.isSwizzled = newValue } }
    }
    
    static var isEphemeralSwizzled: Bool {
        get { syncQueue.sync { ephemeralMethodItem.isSwizzled } }
        set { syncQueue.sync { ephemeralMethodItem.isSwizzled = newValue } }
    }
    
    private static let defaultMethodItem: MethodItem = {
        return MethodItem(selector: #selector(getter: URLSessionConfiguration.default))
    }()
    
    private static let ephemeralMethodItem: MethodItem = {
        return MethodItem(selector: #selector(getter: URLSessionConfiguration.ephemeral))
    }()
    
    @objc(defaultSessionConfiguration)
    private class var `default`: URLSessionConfiguration {
        return defaultMethodItem.makeStubRegisteredConfiguration()
    }
    
    @objc(ephemeralSessionConfiguration)
    private class var ephemeral: URLSessionConfiguration {
        return ephemeralMethodItem.makeStubRegisteredConfiguration()
    }
}

extension URLSessionConfigurationSwizzler {
    private class MethodItem: NSObject {
        private typealias CreationFunction = @convention(c)
            (AnyClass, Selector) -> URLSessionConfiguration
        
        private let selector: Selector
        private let originalMethod: Method
        private let originalImplementation: IMP
        private let swizzlerImplementation: IMP
        
        var isSwizzled: Bool = false {
            didSet {
                if isSwizzled == oldValue { return }
                let implementation = isSwizzled ? swizzlerImplementation : originalImplementation
                method_setImplementation(originalMethod, implementation)
            }
        }
        
        init(selector: Selector) {
            let originalClass = URLSessionConfiguration.self
            let swizzlerClass = URLSessionConfigurationSwizzler.self
            
            guard let originalMethod = class_getClassMethod(originalClass, selector),
                let swizzlerMethod = class_getClassMethod(swizzlerClass, selector)
                else { fatalError("Failed to get class method \(selector)") }
            
            self.selector = selector
            self.originalMethod = originalMethod
            self.originalImplementation = method_getImplementation(originalMethod)
            self.swizzlerImplementation = method_getImplementation(swizzlerMethod)
            
            super.init()
        }
        
        func makeStubRegisteredConfiguration() -> URLSessionConfiguration {
            let result = makeOriginalConfiguration()
            URLProtocolService.registerStub(in: result)
            return result
        }
        
        private func makeOriginalConfiguration() -> URLSessionConfiguration {
            return originalFunction(URLSessionConfiguration.self, selector)
        }
        
        private var originalFunction: CreationFunction {
            return unsafeBitCast(originalImplementation, to: CreationFunction.self)
        }
    }
}
