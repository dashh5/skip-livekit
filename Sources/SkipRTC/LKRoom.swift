// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.__
#else
import LiveKit
#endif

public final class LKRoom {
    public enum LKConnectionState: String {
        case connecting
        case connected
        case disconnected
        case reconnecting
    }
    #if SKIP
    public let room: io.livekit.android.room.Room

    public init() {
        let context = skip.foundation.ProcessInfo.processInfo.androidContext
        self.room = io.livekit.android.LiveKit.create(context)
    }

    public func connect(url: String, token: String) async throws {
        _ = try await room.connect(url: url, token: token, options: io.livekit.android.ConnectOptions())
    }

    public func disconnect() async {
        room.disconnect()
    }

    public var sid: String? {
        room.sid?.sid
    }

    public var connectionState: LKConnectionState {
        switch room.state {
        case io.livekit.android.room.Room.State.CONNECTING: return .connecting
        case io.livekit.android.room.Room.State.CONNECTED: return .connected
        case io.livekit.android.room.Room.State.DISCONNECTED: return .disconnected
        case io.livekit.android.room.Room.State.RECONNECTING: return .reconnecting
        default: return .disconnected
        }
    }
    #else
    public let room: LiveKit.Room

    public init() {
        self.room = LiveKit.Room()
    }

    public func connect(url: String, token: String) async throws {
        try await room.connect(url: url, token: token)
    }

    public func disconnect() async {
        await room.disconnect()
    }

    public var sid: String? {
        guard let sid = room.sid else { return nil }
        return "\(sid)"
    }

    public var connectionState: LKConnectionState {
        switch room.connectionState {
        case .connecting: return .connecting
        case .connected: return .connected
        case .disconnected: return .disconnected
        case .reconnecting: return .reconnecting
        @unknown default: return .disconnected
        }
    }
    #endif
}


