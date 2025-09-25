// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.datastream.incoming.__
#else
import LiveKit
#endif

public final class LKByteStreamReader: @unchecked Sendable {
    #if SKIP
    public let android: io.livekit.android.room.datastream.incoming.ByteStreamReceiver
    init(_ receiver: io.livekit.android.room.datastream.incoming.ByteStreamReceiver) { self.android = receiver }

    public func readAll() async throws -> Data {
        return Data()
    }
    #else
    public let ios: LiveKit.ByteStreamReader
    init(_ reader: LiveKit.ByteStreamReader) { self.ios = reader }

    public func readAll() async throws -> Data {
        try await ios.readAll()
    }
    #endif
}


