import Foundation

// https://www.objc.io/blog/2019/01/15/atomic-variables-part-2/
final class Atomic<A> {
    private let queue = DispatchQueue(label: "Atomic serial queue")
    private var _value: A
    
    init(_ value: A) {
        _value = value
    }
    
    var value: A {
        return queue.sync { _value }
    }
    
    func mutate(_ transform: (inout A) -> Void) {
        queue.sync {
            transform(&_value)
        }
    }
}
