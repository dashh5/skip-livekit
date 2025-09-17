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
    func roomDidConnect(_ room: LKRoom)
    func roomIsReconnecting(_ room: LKRoom)
    func roomDidReconnect(_ room: LKRoom)
    func room(_ room: LKRoom, didDisconnectWithError error: Error?)
    func room(_ room: LKRoom, participant: LKParticipant, didUpdateAttributes attributes: [String: String])
    func room(_ room: LKRoom, participantDidConnect participant: LKParticipant)
    func room(_ room: LKRoom, participantDidDisconnect participant: LKParticipant)
    func room(_ room: LKRoom, didUpdateActiveSpeakers speakers: [LKParticipant])
    func room(_ room: LKRoom, didUpdateMetadata metadata: String?)
    func room(_ room: LKRoom, didReceiveData data: Data, from participant: LKParticipant?)
}

public extension LKRoomDelegate {
    func roomDidConnect(_ room: LKRoom) {}
    func roomIsReconnecting(_ room: LKRoom) {}
    func roomDidReconnect(_ room: LKRoom) {}
    func room(_ room: LKRoom, didDisconnectWithError error: Error?) {}
    func room(_ room: LKRoom, participant: LKParticipant, didUpdateAttributes attributes: [String: String]) {}
    func room(_ room: LKRoom, participantDidConnect participant: LKParticipant) {}
    func room(_ room: LKRoom, participantDidDisconnect participant: LKParticipant) {}
    func room(_ room: LKRoom, didUpdateActiveSpeakers speakers: [LKParticipant]) {}
    func room(_ room: LKRoom, didUpdateMetadata metadata: String?) {}
    func room(_ room: LKRoom, didReceiveData data: Data, from participant: LKParticipant?) {}
}

extension LKRoom {
    private final class _IOSDelegateAdapter: NSObject, RoomDelegate, @unchecked Sendable {
        weak var owner: LKRoom?
        weak var delegate: LKRoomDelegate?
        init(owner: LKRoom, delegate: LKRoomDelegate) {
            self.owner = owner
            self.delegate = delegate
        }
        func roomDidConnect(_ room: Room) { if let o = owner { delegate?.roomDidConnect(o) } }
        func roomIsReconnecting(_ room: Room) { if let o = owner { delegate?.roomIsReconnecting(o) } }
        func roomDidReconnect(_ room: Room) { if let o = owner { delegate?.roomDidReconnect(o) } }
        func room(_ room: Room, didDisconnectWithError error: LiveKitError?) { if let o = owner { delegate?.room(o, didDisconnectWithError: error) } }
        func room(_ room: Room, participant: Participant, didUpdateAttributes attributes: [String : String]) {
            guard let o = owner else { return }
            delegate?.room(o, participant: LKParticipant(participant), didUpdateAttributes: attributes)
        }
        func room(_ room: Room, participantDidConnect participant: Participant) {
            guard let o = owner else { return }
            delegate?.room(o, participantDidConnect: LKParticipant(participant))
        }
        func room(_ room: Room, participantDidDisconnect participant: Participant) {
            guard let o = owner else { return }
            delegate?.room(o, participantDidDisconnect: LKParticipant(participant))
        }
        func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {
            guard let o = owner else { return }
            delegate?.room(o, didUpdateActiveSpeakers: participants.map { LKParticipant($0) })
        }
        func room(_ room: Room, didUpdateMetadata metadata: String?) {
            guard let o = owner else { return }
            delegate?.room(o, didUpdateMetadata: metadata)
        }
    }

    #if SKIP
    private func startAndroidEventForwarding(to delegate: LKRoomDelegate) {
        // Cancel previous
        androidEventJob?.cancel()
        androidEventJob = kotlinx.coroutines.GlobalScope.INSTANCE.launch(context: nil, start: kotlinx.coroutines.CoroutineStart.DEFAULT, block: { [weak self] in
            guard let self = self else { return }
            try? await self.room.events.collect { event in
                switch event {
                case is io.livekit.android.events.RoomEvent.Connected:
                    delegate.roomDidConnect(self)
                case is io.livekit.android.events.RoomEvent.Reconnecting:
                    delegate.roomIsReconnecting(self)
                case is io.livekit.android.events.RoomEvent.Reconnected:
                    delegate.roomDidReconnect(self)
                case let e as io.livekit.android.events.RoomEvent.Disconnected:
                    delegate.room(self, didDisconnectWithError: e.error)
                case let e as io.livekit.android.events.RoomEvent.ParticipantAttributesChanged:
                    delegate.room(self, participant: LKParticipant(e.participant), didUpdateAttributes: e.changedAttributes)
                case let e as io.livekit.android.events.RoomEvent.ParticipantConnected:
                    delegate.room(self, participantDidConnect: LKParticipant(e.participant))
                case let e as io.livekit.android.events.RoomEvent.ParticipantDisconnected:
                    delegate.room(self, participantDidDisconnect: LKParticipant(e.participant))
                case let e as io.livekit.android.events.RoomEvent.ActiveSpeakersChanged:
                    delegate.room(self, didUpdateActiveSpeakers: e.speakers.map { LKParticipant($0) })
                case let e as io.livekit.android.events.RoomEvent.RoomMetadataChanged:
                    delegate.room(self, didUpdateMetadata: e.newMetadata)
                case let e as io.livekit.android.events.RoomEvent.DataReceived:
                    let data = Data(e.data)
                    let from = e.participant != nil ? LKParticipant(e.participant!) : nil
                    delegate.room(self, didReceiveData: data, from: from)
                default:
                    break
                }
            }
        })
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
    }
}


