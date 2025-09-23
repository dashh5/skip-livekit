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
    init(_ receiver: io.livekit.android.room.datastream.incoming.TextStreamReceiver) { self.android = receiver }

    public func readAll() async throws -> String {
        let chunks = try await android.readAll()
        var result = ""
        for chunk in chunks { result += chunk }
        return result
    }
    #else
    public let ios: LiveKit.TextStreamReader
    init(_ reader: LiveKit.TextStreamReader) { self.ios = reader }

    public func readAll() async throws -> String {
        try await ios.readAll()
    }
    #endif
}


