// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.events.__
import io.livekit.android.room.participant.__
import kotlinx.coroutines.__
#else
import LiveKit
#endif

public protocol LKRoomDelegate: AnyObject {
    func lk_roomDidConnect(_ room: LKRoom)
    func lk_roomIsReconnecting(_ room: LKRoom)
    func lk_roomDidReconnect(_ room: LKRoom)
    func lk_roomDidDisconnect(_ room: LKRoom, error: Error?)
    func lk_roomParticipantAttributes(_ room: LKRoom, participant: LKParticipant, attributes: [String: String])
    func lk_roomParticipantConnected(_ room: LKRoom, participant: LKParticipant)
    func lk_roomParticipantDisconnected(_ room: LKRoom, participant: LKParticipant)
    func lk_roomActiveSpeakers(_ room: LKRoom, speakers: [LKParticipant])
    func lk_roomMetadata(_ room: LKRoom, metadata: String?)
    func lk_roomData(_ room: LKRoom, data: Data, participant: LKParticipant?)
}

public extension LKRoomDelegate {
    func lk_roomDidConnect(_ room: LKRoom) {}
    func lk_roomIsReconnecting(_ room: LKRoom) {}
    func lk_roomDidReconnect(_ room: LKRoom) {}
    func lk_roomDidDisconnect(_ room: LKRoom, error: Error?) {}
    func lk_roomParticipantAttributes(_ room: LKRoom, participant: LKParticipant, attributes: [String: String]) {}
    func lk_roomParticipantConnected(_ room: LKRoom, participant: LKParticipant) {}
    func lk_roomParticipantDisconnected(_ room: LKRoom, participant: LKParticipant) {}
    func lk_roomActiveSpeakers(_ room: LKRoom, speakers: [LKParticipant]) {}
    func lk_roomMetadata(_ room: LKRoom, metadata: String?) {}
    func lk_roomData(_ room: LKRoom, data: Data, participant: LKParticipant?) {}
}

// Optional compatibility protocol exposing iOS-native LiveKit-style names.
public protocol LKRoomDelegateIOSCompat: AnyObject {
    func roomDidConnect(_ room: LKRoom)
    func roomIsReconnecting(_ room: LKRoom)
    func roomDidReconnect(_ room: LKRoom)
    func room(_ room: LKRoom, didDisconnectWithError error: Error?)
    func room(_ room: LKRoom, participant: LKParticipant, didUpdateAttributes attributes: [String: String])
    func room(_ room: LKRoom, participantDidConnect participant: LKParticipant)
    func room(_ room: LKRoom, participantDidDisconnect participant: LKParticipant)
    func room(_ room: LKRoom, didUpdateSpeakingParticipants participants: [LKParticipant])
    func room(_ room: LKRoom, didUpdateMetadata metadata: String?)
    func room(_ room: LKRoom, didReceiveData data: Data, participant: LKParticipant?)
}

public extension LKRoomDelegateIOSCompat {
    func roomDidConnect(_ room: LKRoom) {}
    func roomIsReconnecting(_ room: LKRoom) {}
    func roomDidReconnect(_ room: LKRoom) {}
    func room(_ room: LKRoom, didDisconnectWithError error: Error?) {}
    func room(_ room: LKRoom, participant: LKParticipant, didUpdateAttributes attributes: [String: String]) {}
    func room(_ room: LKRoom, participantDidConnect participant: LKParticipant) {}
    func room(_ room: LKRoom, participantDidDisconnect participant: LKParticipant) {}
    func room(_ room: LKRoom, didUpdateSpeakingParticipants participants: [LKParticipant]) {}
    func room(_ room: LKRoom, didUpdateMetadata metadata: String?) {}
    func room(_ room: LKRoom, didReceiveData data: Data, participant: LKParticipant?) {}
}

extension LKRoom {
    // MARK: - Delegate management
    public func add(delegate: LKRoomDelegate) {
        #if SKIP
        startAndroidEventForwarding(to: delegate)
        #else
        let key = ObjectIdentifier(delegate)
        if let existing = iosDelegateAdapters[key] {
            room.delegates.remove(delegate: existing)
        }
        let adapter = _IOSDelegateAdapter(owner: self, delegate: delegate)
        iosDelegateAdapters[key] = adapter
        room.delegates.add(delegate: adapter)
        #endif
    }

    public func remove(delegate: LKRoomDelegate) {
        #if SKIP
        androidEventJob?.cancel()
        androidEventJob = nil
        #else
        let key = ObjectIdentifier(delegate)
        if let adapter = iosDelegateAdapters.removeValue(forKey: key) {
            room.delegates.remove(delegate: adapter)
        }
        #endif
    }
    #if !SKIP
    private final class _IOSDelegateAdapter: NSObject, LiveKit.RoomDelegate, @unchecked Sendable {
        weak var owner: LKRoom?
        weak var delegate: LKRoomDelegate?
        init(owner: LKRoom, delegate: LKRoomDelegate) {
            self.owner = owner
            self.delegate = delegate
        }
        func roomDidConnect(_ room: LiveKit.Room) {
            if let o = owner {
                delegate?.lk_roomDidConnect(o)
                (delegate as? LKRoomDelegateIOSCompat)?.roomDidConnect(o)
                // Deliver initial attributes snapshot for existing remote participants
                for (_, rp) in room.remoteParticipants {
                    let attrs = rp.attributes
                    if !attrs.isEmpty {
                        let id = rp.identity?.stringValue ?? "<unknown>"
                        let keys = Array(attrs.keys)
                        print("Skip→Swift(iOS): initial didUpdateAttributes snapshot identity=\(id) keys=\(keys)")
                        DispatchQueue.main.async {
                            self.delegate?.lk_roomParticipantAttributes(o, participant: LKParticipant(rp), attributes: attrs)
                            self.delegate?.room(o, participant: LKParticipant(rp), didUpdateAttributes: attrs)
                        }
                    }
                    // If backend encodes agent state in metadata, mirror it as an attributes update for Swift bridge
                    let hasState = attrs.keys.contains("lk.agent.state")
                    if !hasState, let jsonStr = rp.metadata, let data = jsonStr.data(using: String.Encoding.utf8),
                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let state = obj["lk.agent.state"] as? String {
                        let mirrored: [String: String] = ["lk.agent.state": state]
                        let id = rp.identity?.stringValue ?? "<unknown>"
                        print("Skip LiveKit(iOS): metadata mirrored to attributes identity=\(id) attrs=\(mirrored)")
                        DispatchQueue.main.async {
                            self.delegate?.lk_roomParticipantAttributes(o, participant: LKParticipant(rp), attributes: mirrored)
                            self.delegate?.room(o, participant: LKParticipant(rp), didUpdateAttributes: mirrored)
                        }
                    }
                }
            }
        }
        func roomIsReconnecting(_ room: LiveKit.Room) { if let o = owner { delegate?.lk_roomIsReconnecting(o); (delegate as? LKRoomDelegateIOSCompat)?.roomIsReconnecting(o) } }
        func roomDidReconnect(_ room: LiveKit.Room) { if let o = owner { delegate?.lk_roomDidReconnect(o); (delegate as? LKRoomDelegateIOSCompat)?.roomDidReconnect(o) } }
        func room(_ room: LiveKit.Room, didDisconnectWithError error: LiveKit.LiveKitError?) { if let o = owner { delegate?.lk_roomDidDisconnect(o, error: error); (delegate as? LKRoomDelegateIOSCompat)?.room(o, didDisconnectWithError: error) } }
        func room(_ room: LiveKit.Room, participant: LiveKit.Participant, didUpdateAttributes attributes: [String : String]) {
            guard let o = owner else { return }
            let id = participant.identity?.stringValue ?? "<unknown>"
            let keys = Array(attributes.keys)
            DispatchQueue.main.async {
                self.delegate?.lk_roomParticipantAttributes(o, participant: LKParticipant(participant), attributes: attributes)
                (self.delegate as? LKRoomDelegateIOSCompat)?.room(o, participant: LKParticipant(participant), didUpdateAttributes: attributes)
            }
        }
        func room(_ room: LiveKit.Room, participantDidConnect participant: LiveKit.RemoteParticipant) {
            guard let o = owner else { return }
            delegate?.lk_roomParticipantConnected(o, participant: LKParticipant(participant))
            (delegate as? LKRoomDelegateIOSCompat)?.room(o, participantDidConnect: LKParticipant(participant))
            // Immediately deliver initial attributes snapshot for newly joined participant
            let attrs = participant.attributes
            if !attrs.isEmpty {
                let id = participant.identity?.stringValue ?? "<unknown>"
                let keys = Array(attrs.keys)
                print("Skip→Swift(iOS): join snapshot didUpdateAttributes identity=\(id) keys=\(keys)")
                DispatchQueue.main.async {
                    self.delegate?.lk_roomParticipantAttributes(o, participant: LKParticipant(participant), attributes: attrs)
                    (self.delegate as? LKRoomDelegateIOSCompat)?.room(o, participant: LKParticipant(participant), didUpdateAttributes: attrs)
                }
            }
            // Mirror metadata state if needed
            if !attrs.keys.contains("lk.agent.state"), let meta = participant.metadata,
               let data = meta.data(using: String.Encoding.utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let state = obj["lk.agent.state"] as? String {
                let id = participant.identity?.stringValue ?? "<unknown>"
                let mirrored = ["lk.agent.state": state]
                print("Skip LiveKit(iOS): join metadata mirrored to attributes identity=\(id) attrs=\(mirrored)")
                DispatchQueue.main.async {
                    self.delegate?.lk_roomParticipantAttributes(o, participant: LKParticipant(participant), attributes: mirrored)
                    (self.delegate as? LKRoomDelegateIOSCompat)?.room(o, participant: LKParticipant(participant), didUpdateAttributes: mirrored)
                }
            }
        }
        func room(_ room: LiveKit.Room, participantDidDisconnect participant: LiveKit.RemoteParticipant) {
            guard let o = owner else { return }
            delegate?.lk_roomParticipantDisconnected(o, participant: LKParticipant(participant))
            (delegate as? LKRoomDelegateIOSCompat)?.room(o, participantDidDisconnect: LKParticipant(participant))
        }
        func room(_ room: LiveKit.Room, didUpdateSpeakingParticipants participants: [LiveKit.Participant]) {
            guard let o = owner else { return }
            let wrapped = participants.map { LKParticipant($0) }
            delegate?.lk_roomActiveSpeakers(o, speakers: wrapped)
            (delegate as? LKRoomDelegateIOSCompat)?.room(o, didUpdateSpeakingParticipants: wrapped)
        }
        func room(_ room: LiveKit.Room, didUpdateMetadata metadata: String?) {
            guard let o = owner else { return }
            delegate?.lk_roomMetadata(o, metadata: metadata)
            (delegate as? LKRoomDelegateIOSCompat)?.room(o, didUpdateMetadata: metadata)
        }
        func room(_ room: LiveKit.Room, participant: LiveKit.Participant, didUpdateMetadata metadata: String?) {
            guard let o = owner else { return }
            // Mirror select metadata fields into attributes for bridging if present
            var mirrored: [String: String] = [:]
            if let meta = metadata, let data = meta.data(using: String.Encoding.utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let state = obj["lk.agent.state"] as? String {
                    mirrored["lk.agent.state"] = state
                }
            }
            if !mirrored.isEmpty {
                let id = participant.identity?.stringValue ?? "<unknown>"
                print("Skip LiveKit(iOS): metadata mirrored to attributes identity=\(id) attrs=\(mirrored)")
                DispatchQueue.main.async {
                    self.delegate?.lk_roomParticipantAttributes(o, participant: LKParticipant(participant), attributes: mirrored)
                    (self.delegate as? LKRoomDelegateIOSCompat)?.room(o, participant: LKParticipant(participant), didUpdateAttributes: mirrored)
                }
            }
        }
    }
    #endif

    #if SKIP
    private func startAndroidEventForwarding(to delegate: LKRoomDelegate) {
        androidEventJob?.cancel()
        let owner = self
        androidEventJob = kotlinx.coroutines.GlobalScope.launch {
            try? await owner.room.events.collect { e in
                switch e {
                case is io.livekit.android.events.RoomEvent.Connected:
                    print("Skip LiveKit: Room connected")
                    try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                        delegate.lk_roomDidConnect(owner)
                        delegate.roomDidConnect(owner)
                    }
                    // Post-connect validation logs for each remote participant
                    for rp in owner.room.remoteParticipants.values {
                        let id = rp.identity?.value ?? "<unknown>"
                        let attrsKeys = Array(rp.attributes.keys)
                        let hasState = rp.attributes.keys.contains("lk.agent.state")
                        let wrapped = LKParticipant(rp)
                        let meta = rp.metadata ?? "<nil>"
                        var full: [String: String] = [:]
                        for (k, v) in rp.attributes { full[k] = v }
                        print("Skip LiveKit: post-connect participants: id=\(id) isAgent=\(wrapped.isAgent) attrsKeys=\(attrsKeys) hasState=\(hasState) metadata=\(meta) attrs=\(full)")
                        // Deliver initial attributes snapshot to Swift to avoid dead zone
                        if !full.isEmpty {
                            let initialKeys = Array(full.keys)
                            print("Skip→Swift: initial didUpdateAttributes snapshot identity=\(id) keys=\(initialKeys)")
                            try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                                delegate.lk_roomParticipantAttributes(owner, participant: LKParticipant(rp), attributes: full)
                                delegate.room(owner, participant: LKParticipant(rp), didUpdateAttributes: full)
                            }
                        }
                        // If backend encodes agent state in metadata, mirror it as an attributes update for Swift bridge
                        if !hasState, let jsonStr = rp.metadata, let data = jsonStr.data(using: String.Encoding.utf8),
                           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let state = obj["lk.agent.state"] as? String {
                            let mirrored: [String: String] = ["lk.agent.state": state]
                            print("Skip LiveKit: metadata mirrored to attributes identity=\(id) attrs=\(mirrored)")
                            try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                                delegate.lk_roomParticipantAttributes(owner, participant: LKParticipant(rp), attributes: mirrored)
                                delegate.room(owner, participant: LKParticipant(rp), didUpdateAttributes: mirrored)
                            }
                        }
                        owner.updateIsAgentCacheAndLog(for: id)
                    }
                    owner.recomputeAgentParticipantAndLog()
                case is io.livekit.android.events.RoomEvent.Reconnecting:
                    print("Skip LiveKit: Room reconnecting")
                    try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                        delegate.lk_roomIsReconnecting(owner)
                        delegate.roomIsReconnecting(owner)
                    }
                case is io.livekit.android.events.RoomEvent.Reconnected:
                    print("Skip LiveKit: Room reconnected")
                    try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                        delegate.lk_roomDidReconnect(owner)
                        delegate.roomDidReconnect(owner)
                    }
                case is io.livekit.android.events.RoomEvent.Disconnected:
                    print("Skip LiveKit: Room disconnected")
                    try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                        delegate.lk_roomDidDisconnect(owner, error: nil)
                        delegate.room(owner, didDisconnectWithError: nil)
                    }
                case let ev as io.livekit.android.events.RoomEvent.ParticipantAttributesChanged:
                    var changed: [String: String] = [:]
                    for (k, v) in ev.changedAttributes { changed[k] = v }
                    let identity = ev.participant.identity?.value ?? "<unknown>"
                    let keys = Array(changed.keys)
                    print("Skip LiveKit: attrs changed identity=\(identity) keys=\(keys)")
                    // Pass through exactly as-is; preserve key casing
                    print("Skip→Swift: calling didUpdateAttributes for identity=\(identity)")
                    try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                        delegate.lk_roomParticipantAttributes(owner, participant: LKParticipant(ev.participant), attributes: changed)
                        delegate.room(owner, participant: LKParticipant(ev.participant), didUpdateAttributes: changed)
                    }
                    owner.updateIsAgentCacheAndLog(for: identity)
                    owner.recomputeAgentParticipantAndLog()
                case let ev as io.livekit.android.events.RoomEvent.ParticipantConnected:
                    let id = ev.participant.identity?.value ?? "<unknown>"
                    print("Skip LiveKit: participant connected identity=\(id)")
                    try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                        delegate.lk_roomParticipantConnected(owner, participant: LKParticipant(ev.participant))
                        delegate.room(owner, participantDidConnect: LKParticipant(ev.participant))
                    }
                    // Immediately deliver initial attributes snapshot for newly joined participant
                    var full: [String: String] = [:]
                    for (k, v) in ev.participant.attributes { full[k] = v }
                    if !full.isEmpty {
                        let keys = Array(full.keys)
                        print("Skip→Swift: join snapshot didUpdateAttributes identity=\(id) keys=\(keys)")
                        try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                            delegate.lk_roomParticipantAttributes(owner, participant: LKParticipant(ev.participant), attributes: full)
                            delegate.room(owner, participant: LKParticipant(ev.participant), didUpdateAttributes: full)
                        }
                    }
                    // Mirror metadata state if needed
                    if !full.keys.contains("lk.agent.state"), let meta = ev.participant.metadata,
                       let data = meta.data(using: String.Encoding.utf8),
                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let state = obj["lk.agent.state"] as? String {
                        let mirrored: [String: String] = ["lk.agent.state": state]
                        print("Skip LiveKit: join metadata mirrored to attributes identity=\(id) attrs=\(mirrored)")
                        try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                            delegate.lk_roomParticipantAttributes(owner, participant: LKParticipant(ev.participant), attributes: mirrored)
                            delegate.room(owner, participant: LKParticipant(ev.participant), didUpdateAttributes: mirrored)
                        }
                    }
                    owner.updateIsAgentCacheAndLog(for: id)
                    owner.recomputeAgentParticipantAndLog()
                case let ev as io.livekit.android.events.RoomEvent.ParticipantDisconnected:
                    let id = ev.participant.identity?.value ?? "<unknown>"
                    print("Skip LiveKit: participant disconnected identity=\(id)")
                    try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                        delegate.lk_roomParticipantDisconnected(owner, participant: LKParticipant(ev.participant))
                        delegate.room(owner, participantDidDisconnect: LKParticipant(ev.participant))
                    }
                    owner.lastIsAgentByIdentity.removeValue(forKey: id)
                    if owner.cachedAgentIdentity == id { owner.cachedAgentIdentity = nil }
                    owner.recomputeAgentParticipantAndLog()
                case let ev as io.livekit.android.events.RoomEvent.ParticipantMetadataChanged:
                    let id = ev.participant.identity?.value ?? "<unknown>"
                    // Mirror select metadata fields into attributes for bridging if present
                    var mirrored: [String: String] = [:]
                    if let meta = ev.participant.metadata, let data = meta.data(using: String.Encoding.utf8),
                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let state = obj["lk.agent.state"] as? String {
                            mirrored["lk.agent.state"] = state
                        }
                    }
                    if !mirrored.isEmpty {
                        print("Skip LiveKit: metadata mirrored to attributes identity=\(id) attrs=\(mirrored)")
                        try? await kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                            delegate.lk_roomParticipantAttributes(owner, participant: LKParticipant(ev.participant), attributes: mirrored)
                            delegate.room(owner, participant: LKParticipant(ev.participant), didUpdateAttributes: mirrored)
                        }
                    }
                    owner.updateIsAgentCacheAndLog(for: id)
                    owner.recomputeAgentParticipantAndLog()
                default:
                    break
                }
            }
        }
    }
    #endif

    public func setDelegate(_ delegate: LKRoomDelegate?) {
        #if SKIP
        if let delegate = delegate {
            startAndroidEventForwarding(to: delegate)
        } else {
            androidEventJob?.cancel()
            androidEventJob = nil
        }
        #else
        if let delegate = delegate {
            add(delegate: delegate)
        } else {
            // Remove all
            for (_, adapter) in iosDelegateAdapters { room.delegates.remove(delegate: adapter) }
            iosDelegateAdapters.removeAll()
        }
        #endif
    }
}


