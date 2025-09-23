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

extension LKRoom {
    #if !SKIP
    private final class _IOSDelegateAdapter: NSObject, RoomDelegate, @unchecked Sendable {
        weak var owner: LKRoom?
        weak var delegate: LKRoomDelegate?
        init(owner: LKRoom, delegate: LKRoomDelegate) {
            self.owner = owner
            self.delegate = delegate
        }
        func roomDidConnect(_ room: Room) { if let o = owner { delegate?.lk_roomDidConnect(o) } }
        func roomIsReconnecting(_ room: Room) { if let o = owner { delegate?.lk_roomIsReconnecting(o) } }
        func roomDidReconnect(_ room: Room) { if let o = owner { delegate?.lk_roomDidReconnect(o) } }
        func room(_ room: Room, didDisconnectWithError error: LiveKitError?) { if let o = owner { delegate?.lk_roomDidDisconnect(o, error: error) } }
        func room(_ room: Room, participant: Participant, didUpdateAttributes attributes: [String : String]) {
            guard let o = owner else { return }
            delegate?.lk_roomParticipantAttributes(o, participant: LKParticipant(participant), attributes: attributes)
        }
        func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
            guard let o = owner else { return }
            delegate?.lk_roomParticipantConnected(o, participant: LKParticipant(participant))
        }
        func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
            guard let o = owner else { return }
            delegate?.lk_roomParticipantDisconnected(o, participant: LKParticipant(participant))
        }
        func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {
            guard let o = owner else { return }
            delegate?.lk_roomActiveSpeakers(o, speakers: participants.map { LKParticipant($0) })
        }
        func room(_ room: Room, didUpdateMetadata metadata: String?) {
            guard let o = owner else { return }
            delegate?.lk_roomMetadata(o, metadata: metadata)
        }
    }
    #endif

    #if SKIP
    private func startAndroidEventForwarding(to delegate: LKRoomDelegate) {
        // Disable event forwarding during SKIP transpile tests to avoid coroutine/flow bridging issues
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
        #if !SKIP
        if let delegate = delegate {
            let adapter = _IOSDelegateAdapter(owner: self, delegate: delegate)
            iosDelegateAdapter = adapter
            room.delegates.add(delegate: adapter)
        } else {
            if let adapter = iosDelegateAdapter {
                room.delegates.remove(delegate: adapter)
            }
            iosDelegateAdapter = nil
        }
        #endif
        #endif
    }
}


