// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.participant.__
#else
import LiveKit
#endif

public class LKParticipant {
    #if SKIP
    public let participant: io.livekit.android.room.participant.Participant

    init(_ participant: io.livekit.android.room.participant.Participant) {
        self.participant = participant
    }

    public var identity: String? { participant.identity?.value }
    public var metadata: String? { participant.metadata }
    public var attributes: [String: String] { participant.attributes }

    public var isAgent: Bool {
        participant.kind == io.livekit.android.room.participant.Participant.Kind.AGENT
    }
    #else
    public let participant: LiveKit.Participant

    init(_ participant: LiveKit.Participant) {
        self.participant = participant
    }

    public var identity: String? { participant.identity?.stringValue }
    public var metadata: String? { participant.metadata }
    public var attributes: [String: String] { participant.attributes }

    public var isAgent: Bool { participant.isAgent }
    #endif
}

public final class LKLocalParticipant: LKParticipant {
    #if SKIP
    public var local: io.livekit.android.room.participant.LocalParticipant { participant as! io.livekit.android.room.participant.LocalParticipant }

    public func setMicrophone(enabled: Bool) async throws {
        _ = try await local.setMicrophoneEnabled(enabled: enabled)
    }

    public func set(metadata: String) async throws {
        local.updateMetadata(metadata)
    }

    public func set(attributes: [String: String]) async throws {
        local.updateAttributes(attributes)
    }

    @discardableResult
    public func sendText(_ text: String, for topic: String) async throws -> Bool {
        let opts = io.livekit.android.room.datastream.StreamTextOptions(topic: topic)
        let result = try await local.sendText(text: text, options: opts)
        if result.isFailure() {
            throw NSError(domain: "SkipRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: result.exceptionOrNull()?.message ?? "sendText failed"]) // SKIP throws
        }
        return true
    }

    public func performRpc(destinationIdentity: String, method: String, payload: String, responseTimeoutSeconds: Double = 10) async throws -> String {
        let id = io.livekit.android.room.participant.Participant.Identity(destinationIdentity)
        let timeout = kotlin.time.Duration.Companion.seconds(responseTimeoutSeconds)
        return try await local.performRpc(destinationIdentity: id, method: method, payload: payload, responseTimeout: timeout)
    }
    #else
    public var local: LiveKit.LocalParticipant { participant as! LiveKit.LocalParticipant }

    public func setMicrophone(enabled: Bool) async throws {
        _ = try await local.setMicrophone(enabled: enabled)
    }

    public func set(metadata: String) async throws {
        try await local.set(metadata: metadata)
    }

    public func set(attributes: [String: String]) async throws {
        try await local.set(attributes: attributes)
    }

    @discardableResult
    public func sendText(_ text: String, for topic: String) async throws -> Bool {
        _ = try await local.sendText(text, for: topic)
        return true
    }

    public func performRpc(destinationIdentity: String, method: String, payload: String, responseTimeoutSeconds: Double = 10) async throws -> String {
        let identity = LiveKit.Participant.Identity(from: destinationIdentity)
        return try await local.performRpc(destinationIdentity: identity, method: method, payload: payload, responseTimeout: responseTimeoutSeconds)
    }
    #endif
}


