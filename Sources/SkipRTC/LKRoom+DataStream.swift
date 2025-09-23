// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.datastream.incoming.__
import io.livekit.android.room.datastream.__
#else
import LiveKit
#endif

public extension LKRoom {
    #if SKIP
    typealias LKTextStreamHandler = (_ reader: LKTextStreamReader, _ fromIdentity: String) -> Void
    typealias LKByteStreamHandler = (_ reader: LKByteStreamReader, _ fromIdentity: String) -> Void

    func registerTextStreamHandler(for topic: String, onNewStream: @escaping LKTextStreamHandler) {
        room.registerTextStreamHandler(topic: topic) { reader, fromIdentity in
            onNewStream(LKTextStreamReader(reader), fromIdentity.value)
        }
    }

    func unregisterTextStreamHandler(for topic: String) {
        room.unregisterTextStreamHandler(topic: topic)
    }

    func registerByteStreamHandler(for topic: String, onNewStream: @escaping LKByteStreamHandler) {
        room.registerByteStreamHandler(topic: topic) { reader, fromIdentity in
            onNewStream(LKByteStreamReader(reader), fromIdentity.value)
        }
    }

    func unregisterByteStreamHandler(for topic: String) {
        room.unregisterByteStreamHandler(topic: topic)
    }
    #else
    typealias LKTextStreamHandler = (_ reader: LKTextStreamReader, _ fromIdentity: String) -> Void
    typealias LKByteStreamHandler = (_ reader: LKByteStreamReader, _ fromIdentity: String) -> Void

    func registerTextStreamHandler(for topic: String, onNewStream: @escaping LKTextStreamHandler) async throws {
        try await room.registerTextStreamHandler(for: topic) { reader, fromIdentity in
            onNewStream(LKTextStreamReader(reader), fromIdentity.stringValue)
        }
    }

    func unregisterTextStreamHandler(for topic: String) async {
        await room.unregisterTextStreamHandler(for: topic)
    }

    func registerByteStreamHandler(for topic: String, onNewStream: @escaping LKByteStreamHandler) async throws {
        try await room.registerByteStreamHandler(for: topic) { reader, fromIdentity in
            onNewStream(LKByteStreamReader(reader), fromIdentity.stringValue)
        }
    }

    func unregisterByteStreamHandler(for topic: String) async {
        await room.unregisterByteStreamHandler(for: topic)
    }
    #endif
}


