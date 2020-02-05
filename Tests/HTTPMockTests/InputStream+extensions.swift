import Foundation

extension InputStream {
    func readAllData() -> Data {
        var result = Data()
        
        let bufferLength = 4096
        var buffer = Data(count: bufferLength)
        
        open()
        
        while true {
            let readLength: Int = buffer.withUnsafeMutableBytes { (bytes) in
                guard let ptr = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    fatalError()
                }
                return read(ptr, maxLength: bufferLength)
            }
            if readLength <= 0 {
                break
            }
            result.append(buffer.prefix(readLength))
        }
        
        assert(streamStatus == .atEnd)
        
        close()
        
        return result
    }
}
