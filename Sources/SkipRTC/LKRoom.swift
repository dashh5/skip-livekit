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
        // Prefer participants that satisfy isAgent() wrapper logic
        for p in room.remoteParticipants.values {
            let wrapped = LKParticipant(p)
            if wrapped.isAgent { return wrapped }
        }
        return nil
    }

    // MARK: - Audio Route
    public var isSpeakerOutputPreferred: Bool {
        get {
            // Prefer speakerphone if selected device is speaker
            return room.audioSwitchHandler?.selectedAudioDevice is com.twilio.audioswitch.AudioDevice.Speakerphone
        }
        set {
            guard let handler = room.audioSwitchHandler else { return }
            // Find existing devices rather than constructing
            let devices = handler.availableAudioDevices
            if newValue {
                var found: com.twilio.audioswitch.AudioDevice? = nil
                for d in devices { if d is com.twilio.audioswitch.AudioDevice.Speakerphone { found = d; break } }
                if let sp = found { handler.selectDevice(sp) }
            } else {
                var found: com.twilio.audioswitch.AudioDevice? = nil
                for d in devices { if d is com.twilio.audioswitch.AudioDevice.Earpiece { found = d; break } }
                if let ep = found { handler.selectDevice(ep) }
            }
        }
    }

    public var remoteParticipants: [String: LKRemoteParticipant] {
        var map: [String: LKRemoteParticipant] = [:]
        for rp in room.remoteParticipants.values {
            if let id = rp.identity?.value { map[id] = LKRemoteParticipant(rp) }
        }
        return map
    }

    // MARK: - Participant Lookup
    public var localIdentity: String? { room.localParticipant.identity?.value }

    public func participant(identity: String) -> LKParticipant? {
        if room.localParticipant.identity?.value == identity { return LKParticipant(room.localParticipant) }
        for rp in room.remoteParticipants.values { if rp.identity?.value == identity { return LKParticipant(rp) } }
        return nil
    }

    public func remoteParticipant(identity: String) -> LKRemoteParticipant? {
        for rp in room.remoteParticipants.values { if rp.identity?.value == identity { return LKRemoteParticipant(rp) } }
        return nil
    }

    public var agentParticipants: [String: LKParticipant] {
        var map: [String: LKParticipant] = [:]
        for rp in room.remoteParticipants.values {
            if rp.kind == io.livekit.android.room.participant.Participant.Kind.AGENT, let id = rp.identity?.value { map[id] = LKParticipant(rp) }
        }
        return map
    }

    public var agentIdentity: String? { agentParticipant?.identity }
    #else
    public let room: LiveKit.Room
    // Store adapters so they can be removed later (supports multiple delegates)
    internal var iosDelegateAdapter: LiveKit.RoomDelegate?
    internal var iosDelegateAdapters: [ObjectIdentifier: LiveKit.RoomDelegate] = [:]

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
    #if os(iOS) || os(tvOS) || os(visionOS)
    public var isSpeakerOutputPreferred: Bool {
        get { LiveKit.AudioManager.shared.audioSession.isSpeakerOutputPreferred }
        set { LiveKit.AudioManager.shared.audioSession.isSpeakerOutputPreferred = newValue }
    }
    #else
    public var isSpeakerOutputPreferred: Bool { false }
    #endif

    // MARK: - Participant Lookup
    public var localIdentity: String? { room.localParticipant.identity?.stringValue }

    public func participant(identity: String) -> LKParticipant? {
        if room.localParticipant.identity?.stringValue == identity { return LKParticipant(room.localParticipant) }
        for (id, rp) in room.remoteParticipants { if id.stringValue == identity { return LKParticipant(rp) } }
        return nil
    }

    public func remoteParticipant(identity: String) -> LKRemoteParticipant? {
        for (id, rp) in room.remoteParticipants { if id.stringValue == identity { return LKRemoteParticipant(rp) } }
        return nil
    }

    public var agentParticipants: [String: LKParticipant] {
        var map: [String: LKParticipant] = [:]
        for (id, rp) in room.agentParticipants { map[id.stringValue] = LKParticipant(rp) }
        return map
    }

    public var agentIdentity: String? { room.agentParticipant?.identity?.stringValue }
    #endif
}


