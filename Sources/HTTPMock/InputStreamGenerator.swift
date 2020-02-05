import Foundation

public protocol InputStreamGenerator {
    var streamLength: Int { get }
    func makeStream() throws -> InputStream
}

public struct DataInputStreamGenerator: InputStreamGenerator {
    public let data: Data
    
    public init(data: Data) {
        self.data = data
    }
    
    public var streamLength: Int {
        return data.count
    }
    
    public func makeStream() -> InputStream {
        return InputStream(data: data)
    }
}

public struct FileInputStreamGenerator: InputStreamGenerator {
    public let fileURL: URL
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    public var streamLength: Int {
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            guard let fileSize = resourceValues.fileSize else { fatalError() }
            return fileSize
        } catch {
            assertionFailure("\(error)")
            return 0
        }
    }
    
    public func makeStream() throws -> InputStream {
        if fileExists(), let result = InputStream(url: fileURL) {
            return result
        }
        
        let description = "The file \"\(fileURL.lastPathComponent)\" "
            + "couldn’t be opened because there is no such file."
        
        let userInfo: [String: Any] = [
            NSURLErrorKey: fileURL,
            NSLocalizedDescriptionKey: description
        ]
        
        throw NSError(domain: NSCocoaErrorDomain,
                      code: NSFileReadNoSuchFileError,
                      userInfo: userInfo)
    }
    
    private func fileExists() -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)
        return exists && !isDir.boolValue
    }
}
