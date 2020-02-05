import Foundation

public class URLProtocolStub: URLProtocol {
    private let stubEntry: StubEntry
    private let schedules: Schedules = Schedules()
    private var streamReader: StreamReader?
    private weak var sessionTask: URLSessionTask?
    private var taskStateKVO: NSKeyValueObservation?
    
    public override class func canInit(with request: URLRequest) -> Bool {
        return StubRegistry.shared.entry(for: request) != nil
    }
    
    public override class func canInit(with task: URLSessionTask) -> Bool {
        return task.currentRequest.map({ canInit(with: $0) }) ?? false
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override init(request: URLRequest,
                         cachedResponse: CachedURLResponse?,
                         client: URLProtocolClient?) {
        guard let stubEntry = StubRegistry.shared.entry(for: request) else {
            preconditionFailure("StubEntry has been unregistered after `canInit(with:)`.")
        }
        self.stubEntry = stubEntry
        super.init(request: request, cachedResponse: nil, client: client)
    }
    
    public convenience init(task: URLSessionTask,
                            cachedResponse: CachedURLResponse?,
                            client: URLProtocolClient?) {
        guard let request = task.currentRequest else { preconditionFailure() }
        self.init(request: request, cachedResponse: cachedResponse, client: client)
        self.sessionTask = task
    }
    
    public override func startLoading() {
        let responseAsset = stubEntry.responseAsset(for: request)
        do {
            if let error = responseAsset.error {
                throw error
            }
            let responseSource = try ResponseSource(request: request, responseAsset: responseAsset)
            scheduleToResume(with: responseSource)
        } catch {
            scheduleToReportError(error, afterDelay: responseAsset.responseDelay)
        }
    }
    
    private func scheduleToResume(with responseSource: ResponseSource) {
        let delay = responseSource.responseDelay
        schedules.resumption = Schedule(delay: delay, work: { [weak self] in
            self?.resume(with: responseSource)
        })
    }
    
    private func scheduleToReportError(_ error: Error, afterDelay delay: TimeInterval) {
        schedules.errorReport = Schedule(delay: delay, work: { [weak self] in
            guard let self = self else { return }
            self.client?.urlProtocol(self, didFailWithError: error)
        })
    }
    
    private func resume(with responseSource: ResponseSource) {
        func setCookiesIfNeeded() {
            guard let cookies = responseSource.httpCookies else { return }
            HTTPCookieStorage.shared.setCookies(cookies, for: request.url,
                                                mainDocumentURL: request.mainDocumentURL)
        }
        
        func redirectIfNeeded() {
            guard let redirectRequest = responseSource.redirectRequest else { return }
            client?.urlProtocol(self, wasRedirectedTo: redirectRequest,
                                redirectResponse: responseSource.response)
        }
        
        func sendResponse() {
            client?.urlProtocol(self, didReceive: responseSource.response,
                                cacheStoragePolicy: .notAllowed)
        }
        
        func startDataStreaming() {
            let contentRange: Range<Int>? = {
                if responseSource.sendsHeadersOnly { return 0..<0 }
                return responseSource.contentRange.map({ Range($0) })
            }()
            streamReader = StreamReader(
                stream: responseSource.bodyStream,
                bytesPerSecond: responseSource.preferredBytesPerSecond,
                range: contentRange
            )
            streamReader?.delegate = self
            streamReader?.start()
        }
        
        setCookiesIfNeeded()
        redirectIfNeeded()
        sendResponse()
        startDataStreaming()
        startObservingTaskState()
    }
    
    private func startObservingTaskState() {
        taskStateKVO = sessionTask?.observe(\.state, options: .initial) { [weak self] (task, _) in
            self?.taskDidChangeState(task)
        }
    }
    
    private func taskDidChangeState(_ task: URLSessionTask) {
        switch task.state {
        case .suspended:
            streamReader?.suspend()
        case .running:
            streamReader?.resume()
        default:
            break
        }
    }
    
    public override func stopLoading() {
        schedules.cancelAll()
        streamReader = nil
        taskStateKVO = nil
    }
}

extension URLProtocolStub: StreamReaderDelegate {
    fileprivate func streamReader(_ streamReader: StreamReader, didRead data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }
    
    fileprivate func streamReaderDidFinish(_ streamReader: StreamReader) {
        self.streamReader = nil
        client?.urlProtocolDidFinishLoading(self)
    }
    
    fileprivate func streamReader(_ streamReader: StreamReader, didFailWithError error: Error) {
        self.streamReader = nil
        client?.urlProtocol(self, didFailWithError: error)
    }
}

// MARK: -

private class Schedule {
    private var timer: Timer?
    private var pendingFireDate: Date?
    
    init(delay: TimeInterval, work: @escaping () -> Void) {
        self.timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { _ in
            work()
        })
    }
    
    deinit {
        cancel()
    }
    
    func cancel() {
        timer?.invalidate()
        timer = nil
    }
    
    func suspend() {
        guard let timer = timer, pendingFireDate == nil else { return }
        pendingFireDate = timer.fireDate
        timer.fireDate = Date.distantFuture
    }
    
    func resume() {
        guard let timer = timer, let pendingFireDate = pendingFireDate else { return }
        timer.fireDate = pendingFireDate
        self.pendingFireDate = nil
    }
}

private class Schedules {
    var errorReport: Schedule?
    var resumption: Schedule?
    
    func cancelAll() {
        errorReport = nil
        resumption = nil
    }
}

// MARK: -

private struct ResponseSource {
    let response: URLResponse
    let bodyStream: InputStream
    let contentRange: ClosedRange<Int>?
    private let originalResponseAsset: HTTPResponseAsset
    private let currentResponseAsset: HTTPResponseAsset
    private let request: URLRequest
    private let url: URL
    
    init(request: URLRequest, responseAsset: HTTPResponseAsset) throws {
        let builder = try ResponseSourceBuilder(request: request, responseAsset: responseAsset)
        self.originalResponseAsset = responseAsset
        self.currentResponseAsset = builder.currentResponseAsset
        self.response = builder.response
        self.bodyStream = builder.bodyStream
        self.contentRange = builder.contentRange
        self.url = builder.url
        self.request = request
    }
    
    var httpCookies: [HTTPCookie]? {
        guard request.httpShouldHandleCookies else { return nil }
        let headerFields = currentResponseAsset.headerFields
        return HTTPCookie.cookies(withResponseHeaderFields: headerFields.dictionary, for: url)
    }
    
    var redirectRequest: URLRequest? {
        guard let redirectURL = currentResponseAsset.redirectURL else { return nil }
        var result = request
        result.url = redirectURL
        return result
    }
    
    var sendsHeadersOnly: Bool {
        return request.httpMethod == HTTPMethod.HEAD.rawValue
    }
    
    var responseDelay: TimeInterval {
        return currentResponseAsset.responseDelay
    }
    
    var preferredBytesPerSecond: Int {
        return currentResponseAsset.preferredBytesPerSecond
    }
}

private class ResponseSourceBuilder {
    private let request: URLRequest
    private let originalResponseAsset: HTTPResponseAsset
    private(set) var currentResponseAsset: HTTPResponseAsset
    private(set) var url: URL!
    private(set) var response: HTTPURLResponse!
    private(set) var bodyStream: InputStream!
    private var bodyStreamLength: Int = 0
    private(set) var contentRange: ClosedRange<Int>?
    
    init(request: URLRequest, responseAsset: HTTPResponseAsset) throws {
        self.request = request
        self.originalResponseAsset = responseAsset
        self.currentResponseAsset = responseAsset
        
        url = request.url
        if url == nil {
            throw makeBadURLError()
        }
        
        setupBodyStream()
        
        handleRangeHeader()
        
        response = makeResponse()
        if response == nil {
            throw makeResponseError()
        }
    }
    
    private func makeBadURLError() -> Error {
        let userInfo: [String: Any] = [NSLocalizedDescriptionKey: "URLRequest.url is nil."]
        return NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: userInfo)
    }
    
    private func setupBodyStream() {
        do {
            try setupBodyStreamWithOriginalResponseAsset()
        } catch {
            setupBodyStreamWithError(error)
        }
    }
    
    private func setupBodyStreamWithOriginalResponseAsset() throws {
        guard let streamGenerator = originalResponseAsset.bodyStreamGenerator else {
            bodyStream = InputStream(data: Data())
            bodyStreamLength = 0
            return
        }
        
        bodyStream = try streamGenerator.makeStream()
        bodyStreamLength = streamGenerator.streamLength
    }
    
    private func setupBodyStreamWithError(_ error: Error) {
        func makeErrorMessageStreamGenerator() -> DataInputStreamGenerator {
            guard let data = error.localizedDescription.data(using: .utf8) else { fatalError() }
            return DataInputStreamGenerator(data: data)
        }
        let streamGenerator = makeErrorMessageStreamGenerator()
        
        currentResponseAsset.statusCode = 500
        currentResponseAsset.headerFields.removeAll()
        currentResponseAsset.bodyStreamGenerator = streamGenerator
        bodyStream = streamGenerator.makeStream()
        bodyStreamLength = streamGenerator.streamLength
    }
    
    private func handleRangeHeader() {
        typealias Name = HTTPHeaderName
        
        let requestHeaders = request.allHTTPHeaderFields ?? [:]
        guard currentResponseAsset.statusCode == 200,
            let rangeString = requestHeaders[Name.range],
            let range = parseRange(from: rangeString)
            else { return }
        
        switch (requestHeaders[Name.ifRange], currentResponseAsset.headerFields[Name.eTag]) {
        case let (requestETag?, responseETag?) where requestETag == responseETag:
            fallthrough
        case (nil, _):
            let rangeStr = "bytes \(range.lowerBound)-\(range.upperBound)/\(bodyStreamLength)"
            contentRange = range
            currentResponseAsset.statusCode = 206
            currentResponseAsset.headerFields[HTTPHeaderName.contentLength] = "\(range.count)"
            currentResponseAsset.headerFields[HTTPHeaderName.contentRange] = rangeStr
        default:
            break
        }
    }
    
    private func parseRange(from string: String) -> ClosedRange<Int>? {
        // https://developer.mozilla.org/docs/Web/HTTP/Headers/Range
        let scanner = Scanner(string: string)
        guard scanner.scanString("bytes=", into: nil) else { return nil }
        
        func scanNumber() -> Int? {
            var number: UInt64 = 0
            guard scanner.scanUnsignedLongLong(&number) else { return nil }
            return numericCast(number)
        }
        
        let lower = scanNumber()
        guard scanner.scanString("-", into: nil) else { return nil }
        let upper = scanNumber()
        guard scanner.isAtEnd else { return nil }
        let maxUpper = bodyStreamLength - 1
        
        switch (lower, upper) {
        case let (lower?, upper?) where lower <= upper && upper <= maxUpper:
            return lower...upper
        case let (lower?, nil) where lower <= maxUpper:
            return lower...maxUpper
        case let (nil, upper?) where 1 <= upper && upper <= maxUpper + 1:
            return (maxUpper + 1 - upper)...maxUpper
        default:
            return nil
        }
    }
    
    private func makeResponse() -> HTTPURLResponse? {
        return HTTPURLResponse(url: url,
                               statusCode: currentResponseAsset.statusCode,
                               httpVersion: "HTTP/1.1",
                               headerFields: currentResponseAsset.headerFields.dictionary)
    }
    
    private func makeResponseError() -> Error {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "Cannot make HTTPURLResponse from HTTPResponseAsset.",
            NSURLErrorKey: url as Any,
            "HTTPStatusCode": currentResponseAsset.statusCode,
            "HTTPHeaderFields": currentResponseAsset.headerFields.dictionary
        ]
        return NSError(domain: NSURLErrorDomain,
                       code: NSURLErrorCannotParseResponse,
                       userInfo: userInfo)
    }
}

// MARK: -

private protocol StreamReaderDelegate: AnyObject {
    func streamReader(_ streamReader: StreamReader, didRead data: Data)
    func streamReaderDidFinish(_ streamReader: StreamReader)
    func streamReader(_ streamReader: StreamReader, didFailWithError error: Error)
}

private class StreamReader {
    private enum Constant {
        static let transferInterval: TimeInterval = 0.25
    }
    
    weak var delegate: StreamReaderDelegate? = nil
    private let stream: InputStream
    private let range: Range<Int>?
    private var buffer: Data
    private var timer: Timer?
    private var countOfBytesRead: Int = 0
    private var pendingFireDate: Date?
    
    init(stream: InputStream, bytesPerSecond: Int, range: Range<Int>? = nil) {
        self.stream = stream
        self.range = range
        let bytesPerTransfer = TimeInterval(bytesPerSecond) * Constant.transferInterval
        self.buffer = Data(count: max(1, Int(bytesPerTransfer)))
    }
    
    deinit {
        tearDown()
    }
    
    private func tearDown() {
        timer?.invalidate()
        timer = nil
        
        stream.close()
    }
    
    func start() {
        stream.open()
        
        skipToRangeStart()
        
        let timer = Timer(fire: Date(), interval: Constant.transferInterval, repeats: true,
                          block: { [weak self] _ in self?.transferData() })
        RunLoop.current.add(timer, forMode: .default)
        self.timer = timer
    }
    
    private func skipToRangeStart() {
        guard let bytesToSkip = range?.lowerBound else { return }
        
        let (quotient, remainder) = bytesToSkip.quotientAndRemainder(dividingBy: buffer.count)
        
        for _ in 0..<quotient {
            readIntoBuffer(maxLength: buffer.count)
        }
        
        readIntoBuffer(maxLength: remainder)
    }
    
    @discardableResult
    private func readIntoBuffer(maxLength: Int) -> Int {
        assert(maxLength >= 0 && maxLength <= buffer.count)
        if maxLength == 0 {
            // 파일 스트림인 경우 maxLength를 0으로 하고 read()하면 streamStatus가 .atEnd로 된다.
            return 0
        }
        return buffer.withUnsafeMutableBytes({ (bytes: UnsafeMutableRawBufferPointer) in
            guard let ptr = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                fatalError()
            }
            return stream.read(ptr, maxLength: maxLength)
        })
    }
    
    private func transferData() {
        let bytesToRead: Int = {
            guard let totalBytes = range?.count else { return buffer.count }
            return min(buffer.count, totalBytes - countOfBytesRead)
        }()
        
        let dataLength = readIntoBuffer(maxLength: bytesToRead)
        
        if dataLength < 0 {
            guard let error = stream.streamError else { fatalError() }
            tearDown()
            delegate?.streamReader(self, didFailWithError: error)
        } else {
            if dataLength > 0 {
                countOfBytesRead += dataLength
                delegate?.streamReader(self, didRead: buffer[0..<dataLength])
            }
            if stream.streamStatus == .atEnd || countOfBytesRead == range?.count {
                tearDown()
                delegate?.streamReaderDidFinish(self)
            }
        }
    }
    
    func cancel() {
        tearDown()
    }
    
    func suspend() {
        guard let timer = timer, pendingFireDate == nil else { return }
        pendingFireDate = timer.fireDate
        timer.fireDate = Date.distantFuture
    }
    
    func resume() {
        guard let timer = timer, let pendingFireDate = pendingFireDate else { return }
        timer.fireDate = pendingFireDate
        self.pendingFireDate = nil
    }
}
