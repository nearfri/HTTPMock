# HTTPMock
[![Swift](https://github.com/nearfri/HTTPMock/actions/workflows/swift.yml/badge.svg)](https://github.com/nearfri/HTTPMock/actions/workflows/swift.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnearfri%2FHTTPMock%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/nearfri/HTTPMock)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnearfri%2FHTTPMock%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/nearfri/HTTPMock)

`HTTPMock`은 HTTP 호출 시 가짜 데이터를 다운로드받을 수 있도록 해주는 라이브러리입니다.
네트워크 호출이 필요한 앱을 서버 없이 유닛 테스트할 때 유용하게 쓸 수 있습니다.

## 사용법

### URLSessionConfiguration에 custom URLProtocol 등록
`URLSession` 사용 시 stub된 데이터를 받을 수 있도록 하기 위해서는 `URLSessionConfiguration.protocolClasses`에
custom class를 등록해야 합니다. 등록하는 방법으로는 아래 세 가지가 있습니다.

`URLSessionConfiguration`에 직접 등록하는 방법입니다.
```swift
let configuration = URLSessionConfiguration.default
URLProtocolService.registerStub(in: configuration)
let session = URLSession(configuration: configuration)
...
```

`URLSessionConfiguration` 생성 시 자동으로 등록하고 싶다면 아래의 메소드를 사용합니다.
```swift
URLProtocolService.registerStubInDefaultConfiguration()
let configuration = URLSessionConfiguration.default
let session = URLSession(configuration: configuration)
...
```

`URLSession`은 생성 후 `configuration` 변경이 불가능합니다. 따라서 `URLSession.shared`를 사용한다면 아래의 메소드를 호출해야 합니다.
```swift
URLProtocolService.registerStubInSharedSession()
```

등록을 해제하고 싶다면 아래의 메소드를 사용합니다.
```swift
URLProtocolService.unregisterStub(from: configuration)
URLProtocolService.unregisterStubFromDefaultConfiguration()
URLProtocolService.unregisterStubFromEphemeralConfiguration()
URLProtocolService.unregisterStubFromSharedSession()
```

### Stub 할 request와 response 설정
```swift
let bundle = Bundle(for: type(of: self))
let responseFileURL = bundle.url(forResource: "items", withExtension: "json")!

stub(when: .isHost("server.com"), then: .fileURL(responseFileURL))

// stub 시 다양한 설정 가능. ex) 2초 딜레이 후 1KB씩 전송
stub(when: .isHost("server.com") && .hasLastPathComponent("items.json"),
     then: .fileURL(responseFileURL)
        .settingResponseDelay(2.0)
        .settingPreferredBytesPerSecond(1_000))

```

순서 상관없이 위 두 작업을 한 후 `URLSession.dataTask(with:)`나 `URLSession.downloadTask(with:)`를 호출하면 stub된 데이터를 얻을 수 있습니다.

## 설치

#### Swift Package Manager
```
.package(url: "https://github.com/nearfri/HTTPMock", from: "0.9.0")
```

## 제한사항
* background session은 지원하지 않습니다. (불가능)
* 업로드 역시 지원하지 않습니다. (불가능한 것으로 알고 있음)
