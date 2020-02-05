import Foundation

public struct HTTPHeaderFields {
    public typealias Element = (name: String, value: String)
    
    private var elements: [Element] = []
    
    public init(_ elements: [Element] = []) {
        for (name, value) in elements {
            self[name] = value
        }
    }
    
    public subscript(name: String) -> String? {
        get { value(for: name) }
        set { setValue(newValue, for: name) }
    }
    
    private func value(for name: String) -> String? {
        return index(forName: name).map({ elements[$0].value })
    }
    
    private mutating func setValue(_ value: String?, for name: String) {
        _ = index(forName: name).map({ elements.remove(at: $0) })
        
        if let value = value {
            elements.append((name, value))
        }
    }
    
    private func index(forName name: String) -> Int? {
        return elements.firstIndex(where: { (element) -> Bool in
            element.name.caseInsensitiveCompare(name) == .orderedSame
        })
    }
    
    public mutating func removeAll() {
        elements.removeAll()
    }
}

extension HTTPHeaderFields: RandomAccessCollection {
    public struct Index: Comparable {
        fileprivate let base: Array<HTTPHeaderFields>.Index
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.base < rhs.base
        }
        
        public static  func == (lhs: Index, rhs: Index) -> Bool {
            return lhs.base == rhs.base
        }
    }
    
    public subscript(position: Index) -> (name: String, value: String) {
        return elements[position.base]
    }
    
    public var startIndex: Index {
        return Index(base: elements.startIndex)
    }
    
    public var endIndex: Index {
        return Index(base: elements.endIndex)
    }
    
    public func index(before i: Index) -> Index {
        return Index(base: elements.index(before: i.base))
    }
    
    public func index(after i: Index) -> Index {
        return Index(base: elements.index(after: i.base))
    }
    
    public var count: Int {
        return elements.count
    }
}

extension HTTPHeaderFields: Equatable {
    public static func == (lhs: HTTPHeaderFields, rhs: HTTPHeaderFields) -> Bool {
        guard lhs.elements.count == rhs.elements.count else {
            return false
        }
        
        return lhs.allSatisfy { (name, value) -> Bool in
            rhs[name] == value
        }
    }
}

public extension HTTPHeaderFields {
    init(_ dictionary: [String: String]) {
        self.init(dictionary.map({ $0 }))
    }
    
    var dictionary: [String: String] {
        return Dictionary(uniqueKeysWithValues: elements)
    }
}

extension HTTPHeaderFields: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(elements)
    }
}

extension HTTPHeaderFields: CustomStringConvertible {
    public var description: String {
        return elements.description
    }
}
