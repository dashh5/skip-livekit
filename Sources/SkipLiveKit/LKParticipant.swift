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
    public var attributes: [String: String] {
        var dict: [String: String] = [:]
        for (k, v) in participant.attributes { dict[k] = v }
        return dict
    }

    public var isAgent: Bool {
        // Primary: SDK-reported kind
        if participant.kind == io.livekit.android.room.participant.Participant.Kind.AGENT { return true }
        let attrs = self.attributes
        // Attributes based signals
        if attrs["lk.agent"]?.lowercased() == "true" { return true }
        if attrs["lk.type"]?.lowercased() == "agent" { return true }
        if attrs.keys.contains("lk.agent.state") { return true }
        // Metadata JSON signals
        if let meta = participant.metadata {
            if let data = meta.data(using: .utf8) {
                if let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let role = obj["role"] as? String, role.lowercased() == "agent" { return true }
                    if let isAgent = obj["is_agent"] as? Bool, isAgent { return true }
                    if let kind = obj["kind"] as? String, kind.lowercased() == "agent" { return true }
                    if let type = obj["type"] as? String, type.lowercased() == "agent" { return true }
                }
            } else if meta.lowercased().contains("agent") {
                // Last resort: raw string contains agent
                return true
            }
        }
        // Heuristic: identity prefix
        if let id = identity?.lowercased(), id.hasPrefix("agent-") { return true }
        return false
    }

    public var agentStateString: String {
        let raw = participant.attributes["lk.agent.state"] ?? "idle"
        return raw
    }

    public var isSpeaking: Bool { participant.isSpeaking }
    public var audioLevel: Float { participant.audioLevel }
    #else
    public let participant: LiveKit.Participant

    init(_ participant: LiveKit.Participant) {
        self.participant = participant
    }

    public var identity: String? { participant.identity?.stringValue }
    public var metadata: String? { participant.metadata }
    public var attributes: [String: String] { participant.attributes }

    public var isAgent: Bool { participant.isAgent }

    public var agentStateString: String { participant.agentStateString }

    public var isSpeaking: Bool { participant.isSpeaking }
    public var audioLevel: Float { participant.audioLevel }
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
        let map = java.util.HashMap<kotlin.String, kotlin.String>()
        for (k, v) in attributes { map.put(k, v) }
        local.updateAttributes(map)
    }

    @discardableResult
    public func sendText(_ text: String, for topic: String) async throws -> Bool {
        let opts = io.livekit.android.room.datastream.StreamTextOptions(topic: topic)
        _ = try await local.sendText(text: text, options: opts)
        return true
    }

    public func performRpc(destinationIdentity: String, method: String, payload: String, responseTimeoutSeconds: Double = 10) async throws -> String {
        let id = io.livekit.android.room.participant.Participant.Identity(destinationIdentity)
        return try await local.performRpc(destinationIdentity: id, method: method, payload: payload)
    }

    public func setCamera(enabled: Bool) async throws {
        _ = try await local.setCameraEnabled(enabled)
    }

    public func streamText(for topic: String) async throws -> LKTextStreamWriter {
        let sender = try await local.streamText(options: io.livekit.android.room.datastream.StreamTextOptions(topic: topic))
        return LKTextStreamWriter(sender)
    }

    public func streamBytes(for topic: String, mimeType: String = "application/octet-stream") async throws -> LKByteStreamWriter {
        let sender = try await local.streamBytes(options: io.livekit.android.room.datastream.StreamBytesOptions(topic: topic, mimeType: mimeType))
        return LKByteStreamWriter(sender)
    }

    @discardableResult
    public func sendFile(_ filePath: String, for topic: String, mimeType: String = "application/octet-stream") async throws -> Bool {
        _ = try await local.sendFile(file: java.io.File(filePath), options: io.livekit.android.room.datastream.StreamBytesOptions(topic: topic, mimeType: mimeType))
        return true
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

    public func setCamera(enabled: Bool) async throws {
        _ = try await local.setCamera(enabled: enabled)
    }

    public func streamText(for topic: String) async throws -> LKTextStreamWriter {
        let writer = try await local.streamText(for: topic)
        return LKTextStreamWriter(writer)
    }

    public func streamBytes(for topic: String, mimeType: String = "application/octet-stream") async throws -> LKByteStreamWriter {
        let writer = try await local.streamBytes(options: LiveKit.StreamByteOptions(topic: topic, mimeType: mimeType))
        return LKByteStreamWriter(writer)
    }

    @discardableResult
    public func sendFile(_ fileURL: URL, for topic: String, mimeType: String = "application/octet-stream") async throws -> Bool {
        _ = try await local.sendFile(fileURL, options: LiveKit.StreamByteOptions(topic: topic, mimeType: mimeType))
        return true
    }
    #endif
}


