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
    typealias LKTextStreamHandler = (_ reader: io.livekit.android.room.datastream.incoming.TextStreamReceiver, _ fromIdentity: String) -> Void

    func registerTextStreamHandler(for topic: String, onNewStream: @escaping LKTextStreamHandler) {
        room.registerTextStreamHandler(topic: topic) { reader, fromIdentity in
            onNewStream(reader, fromIdentity.value)
        }
    }

    func unregisterTextStreamHandler(for topic: String) {
        room.unregisterTextStreamHandler(topic: topic)
    }
    #else
    typealias LKTextStreamHandler = (_ reader: LiveKit.TextStreamReader, _ fromIdentity: String) -> Void

    func registerTextStreamHandler(for topic: String, onNewStream: @escaping LKTextStreamHandler) async throws {
        try await room.registerTextStreamHandler(for: topic) { reader, fromIdentity in
            onNewStream(reader, fromIdentity.stringValue)
        }
    }

    func unregisterTextStreamHandler(for topic: String) async {
        await room.unregisterTextStreamHandler(for: topic)
    }
    #endif
}


