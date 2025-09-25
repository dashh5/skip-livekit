// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.participant.__
import io.livekit.android.room.track.__
#else
import LiveKit
#endif

public final class LKRemoteParticipant: LKParticipant {
    #if SKIP
    public var remote: io.livekit.android.room.participant.RemoteParticipant { participant as! io.livekit.android.room.participant.RemoteParticipant }

    private func remoteAudioPublication() -> io.livekit.android.room.track.RemoteTrackPublication? {
        return remote.getTrackPublication(io.livekit.android.room.track.Track.Source.MICROPHONE) as? io.livekit.android.room.track.RemoteTrackPublication
    }

    private func remoteVideoPublication() -> io.livekit.android.room.track.RemoteTrackPublication? {
        return remote.getTrackPublication(io.livekit.android.room.track.Track.Source.CAMERA) as? io.livekit.android.room.track.RemoteTrackPublication
    }

    public func setAudioSubscribed(_ subscribed: Bool) {
        remoteAudioPublication()?.setSubscribed(subscribed)
    }

    public func setAudioEnabled(_ enabled: Bool) {
        remoteAudioPublication()?.setEnabled(enabled)
    }

    public func setVideoSubscribed(_ subscribed: Bool) {
        remoteVideoPublication()?.setSubscribed(subscribed)
    }

    public func setVideoEnabled(_ enabled: Bool) {
        remoteVideoPublication()?.setEnabled(enabled)
    }

    public func setAudioVolume(_ volume: Double) {
        if let track = remote.getTrackPublication(io.livekit.android.room.track.Track.Source.MICROPHONE)?.track as? io.livekit.android.room.track.RemoteAudioTrack {
            track.setVolume(volume)
        }
    }

    public override var isSpeaking: Bool { participant.isSpeaking }
    public override var audioLevel: Float { participant.audioLevel }
    public var publications: [String: Any] { [:] }
    #else
    public var remote: LiveKit.RemoteParticipant { participant as! LiveKit.RemoteParticipant }

    private func remoteAudioPublication() -> LiveKit.RemoteTrackPublication? {
        return (remote.audioTracks.first as? LiveKit.RemoteTrackPublication)
            ?? (remote.trackPublications.values.first { $0.kind == .audio } as? LiveKit.RemoteTrackPublication)
    }

    private func remoteVideoPublication() -> LiveKit.RemoteTrackPublication? {
        return (remote.videoTracks.first as? LiveKit.RemoteTrackPublication)
            ?? (remote.trackPublications.values.first { $0.kind == .video } as? LiveKit.RemoteTrackPublication)
    }

    public func setAudioSubscribed(_ subscribed: Bool) async throws {
        try await remoteAudioPublication()?.set(subscribed: subscribed)
    }

    public func setAudioEnabled(_ enabled: Bool) async throws {
        try await remoteAudioPublication()?.set(enabled: enabled)
    }

    public func setVideoSubscribed(_ subscribed: Bool) async throws {
        try await remoteVideoPublication()?.set(subscribed: subscribed)
    }

    public func setVideoEnabled(_ enabled: Bool) async throws {
        try await remoteVideoPublication()?.set(enabled: enabled)
    }

    public override var isSpeaking: Bool { participant.isSpeaking }
    public override var audioLevel: Float { participant.audioLevel }
    public var publications: [String: LiveKit.TrackPublication] {
        var map: [String: LiveKit.TrackPublication] = [:]
        for (sid, pub) in remote.trackPublications { map[sid.stringValue] = pub }
        return map
    }
    #endif
}


