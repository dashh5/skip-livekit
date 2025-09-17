// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.datastream.__
import io.livekit.android.room.datastream.outgoing.__
#else
import LiveKit
#endif

public final class LKByteStreamWriter: @unchecked Sendable {
    #if SKIP
    public let sender: io.livekit.android.room.datastream.outgoing.ByteStreamSender
    init(_ sender: io.livekit.android.room.datastream.outgoing.ByteStreamSender) { self.sender = sender }

    public func write(_ data: Data) async throws {
        let result = try await sender.write(data.toByteArray())
        if result.isFailure() { throw NSError(domain: "SkipRTC", code: -1) }
    }

    public func close(reason: String? = nil) async throws {
        try await sender.close(reason)
    }
    #else
    public let writer: LiveKit.ByteStreamWriter
    init(_ writer: LiveKit.ByteStreamWriter) { self.writer = writer }

    public func write(_ data: Data) async throws {
        try await writer.write(data)
    }

    public func close(reason: String? = nil) async throws {
        try await writer.close(reason: reason)
    }
    #endif
}

#if SKIP
private extension Data {
    func toByteArray() -> [UInt8] { [UInt8](self) }
}
#endif


