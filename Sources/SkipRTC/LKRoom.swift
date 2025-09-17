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
    // Android event forwarding job
    internal var androidEventJob: kotlinx.coroutines.Job?

    public init() {
        let context = skip.foundation.ProcessInfo.processInfo.androidContext
        self.room = io.livekit.android.LiveKit.create(context)
    }

    public func connect(url: String, token: String) async throws {
        _ = try await room.connect(url: url, token: token, options: io.livekit.android.ConnectOptions())
    }

    public func connect(url: String, token: String, enableMicrophone: Bool) async throws {
        let options = io.livekit.android.ConnectOptions(audio: enableMicrophone)
        _ = try await room.connect(url: url, token: token, options: options)
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

    public var localParticipant: LKLocalParticipant {
        LKLocalParticipant(room.localParticipant)
    }

    public var agentParticipant: LKParticipant? {
        // Android SDK does not expose isAgent directly; infer from Participant.Kind
        let agents = room.remoteParticipants.values.filter { $0.kind == io.livekit.android.room.participant.Participant.Kind.AGENT }
        guard let first = agents.first else { return nil }
        return LKParticipant(first)
    }

    // MARK: - Audio Route
    public var isSpeakerOutputPreferred: Bool {
        get {
            // Prefer speakerphone if selected device is speaker
            return room.audioSwitchHandler?.selectedAudioDevice is com.twilio.audioswitch.AudioDevice.Speakerphone
        }
        set {
            guard let handler = room.audioSwitchHandler else { return }
            if newValue {
                handler.selectDevice(com.twilio.audioswitch.AudioDevice.Speakerphone())
            } else {
                handler.selectDevice(com.twilio.audioswitch.AudioDevice.Earpiece())
            }
        }
    }

    public var remoteParticipants: [String: LKRemoteParticipant] {
        var map: [String: LKRemoteParticipant] = [:]
        for (id, rp) in room.remoteParticipants {
            map[id.value] = LKRemoteParticipant(rp)
        }
        return map
    }
    #else
    public let room: LiveKit.Room
    // Store the adapter so it can be removed later
    internal var iosDelegateAdapter: RoomDelegate?

    public init() {
        self.room = LiveKit.Room()
    }

    public func connect(url: String, token: String) async throws {
        try await room.connect(url: url, token: token)
    }

    public func connect(url: String, token: String, enableMicrophone: Bool) async throws {
        try await room.connect(url: url, token: token, connectOptions: LiveKit.ConnectOptions(enableMicrophone: enableMicrophone))
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

    public var localParticipant: LKLocalParticipant {
        LKLocalParticipant(room.localParticipant)
    }

    public var agentParticipant: LKParticipant? {
        guard let agent = room.agentParticipant else { return nil }
        return LKParticipant(agent)
    }

    public var remoteParticipants: [String: LKRemoteParticipant] {
        var map: [String: LKRemoteParticipant] = [:]
        for (id, rp) in room.remoteParticipants { map[id.stringValue] = LKRemoteParticipant(rp) }
        return map
    }

    // MARK: - Audio Route
    public var isSpeakerOutputPreferred: Bool {
        get { LiveKit.AudioManager.shared.audioSession.isSpeakerOutputPreferred }
        set { LiveKit.AudioManager.shared.audioSession.isSpeakerOutputPreferred = newValue }
    }
    #endif
}


