// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.datastream.incoming.__
#else
import LiveKit
#endif

public final class LKTextStreamReader: @unchecked Sendable {
    #if SKIP
    public let android: io.livekit.android.room.datastream.incoming.TextStreamReceiver
    init(_ receiver: io.livekit.android.room.datastream.incoming.TextStreamReceiver) {
        self.android = receiver
    }

    public func readAll() async throws -> String {
        let chunks = try await android.readAll()
        var result = ""
        for chunk in chunks { result += chunk }
        return result
    }

    public var info: TextStreamInfo { TextStreamInfo(android.info) }
    #else
    public let ios: LiveKit.TextStreamReader
    init(_ reader: LiveKit.TextStreamReader) { self.ios = reader }

    public func readAll() async throws -> String {
        try await ios.readAll()
    }
    public var info: TextStreamInfo { TextStreamInfo(ios.info) }
    #endif
}

#if !SKIP
extension LKTextStreamReader: AsyncSequence {
    public typealias Element = String
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var inner: LiveKit.TextStreamReader.AsyncChunks
        init(_ inner: LiveKit.TextStreamReader.AsyncChunks) { self.inner = inner }
        public mutating func next() async throws -> String? { try await inner.next() }
    }
    public func makeAsyncIterator() -> AsyncIterator { AsyncIterator(ios.makeAsyncIterator()) }
}
#endif


