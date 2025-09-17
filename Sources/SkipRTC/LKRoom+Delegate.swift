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
}

public extension LKRoomDelegate {
    func roomDidConnect(_ room: LKRoom) {}
    func roomIsReconnecting(_ room: LKRoom) {}
    func roomDidReconnect(_ room: LKRoom) {}
    func room(_ room: LKRoom, didDisconnectWithError error: Error?) {}
    func room(_ room: LKRoom, participant: LKParticipant, didUpdateAttributes attributes: [String: String]) {}
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


