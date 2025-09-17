// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.datastream.__
import io.livekit.android.room.datastream.outgoing.__
#else
import LiveKit
#endif

public final class LKTextStreamWriter: @unchecked Sendable {
    #if SKIP
    public let sender: io.livekit.android.room.datastream.outgoing.TextStreamSender
    init(_ sender: io.livekit.android.room.datastream.outgoing.TextStreamSender) { self.sender = sender }

    public var isOpen: Bool { !sender.isClosed }

    public func write(_ text: String) async throws {
        let result = try await sender.write(text)
        if result.isFailure() { throw NSError(domain: "SkipRTC", code: -1) }
    }

    public func close(reason: String? = nil) async throws {
        try await sender.close(reason)
    }
    #else
    public let writer: LiveKit.TextStreamWriter
    init(_ writer: LiveKit.TextStreamWriter) { self.writer = writer }

    public var isOpen: Bool { get async { await writer.isOpen } }

    public func write(_ text: String) async throws {
        try await writer.write(text)
    }

    public func close(reason: String? = nil) async throws {
        try await writer.close(reason: reason)
    }
    #endif
}
