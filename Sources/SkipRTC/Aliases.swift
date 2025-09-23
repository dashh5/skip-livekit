// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation

// Public typealiases to mirror LiveKit's public API names.

public typealias Room = LKRoom
public typealias Participant = LKParticipant
public typealias RemoteParticipant = LKRemoteParticipant
public typealias LocalParticipant = LKLocalParticipant

public typealias TextStreamReader = LKTextStreamReader
public typealias TextStreamWriter = LKTextStreamWriter
public typealias ByteStreamReader = LKByteStreamReader
public typealias ByteStreamWriter = LKByteStreamWriter

public typealias RoomDelegate = LKRoomDelegate
public typealias ConnectionState = LKRoom.LKConnectionState

// Stream info types (iOS-only underlying types)
#if !SKIP
import LiveKit
public typealias TextStreamInfo = LiveKit.TextStreamInfo
public typealias ByteStreamInfo = LiveKit.ByteStreamInfo
#endif

public extension LKParticipant {
    typealias Identity = String
}


