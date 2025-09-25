// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if !SKIP
import LiveKit
#endif

public struct LKTextStreamInfo: Sendable {
    public enum OperationType: Int, Sendable { case create, update, delete, reaction }

    public let id: String
    public let topic: String
    public let timestamp: Date
    public let totalLength: Int?
    public let attributes: [String: String]
    public let operationType: OperationType
    public let version: Int
    public let replyToStreamID: String?
    public let attachedStreamIDs: [String]
    public let generated: Bool

    #if SKIP
    init(_ android: io.livekit.android.room.datastream.TextStreamInfo) {
        self.id = android.id
        self.topic = android.topic
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(android.timestampMs) / 1000.0)
        if let size = android.totalSize { self.totalLength = Int(size) } else { self.totalLength = nil }
        var attrs: [String: String] = [:]
        for (k, v) in android.attributes { attrs[k] = v }
        self.attributes = attrs
        switch android.operationType {
        case io.livekit.android.room.datastream.TextStreamInfo.OperationType.CREATE: self.operationType = .create
        case io.livekit.android.room.datastream.TextStreamInfo.OperationType.UPDATE: self.operationType = .update
        case io.livekit.android.room.datastream.TextStreamInfo.OperationType.DELETE: self.operationType = .delete
        case io.livekit.android.room.datastream.TextStreamInfo.OperationType.REACTION: self.operationType = .reaction
        default: self.operationType = .update
        }
        self.version = android.version
        self.replyToStreamID = android.replyToStreamId
        var attached: [String] = []
        for s in android.attachedStreamIds { attached.append(s) }
        self.attachedStreamIDs = attached
        self.generated = android.generated
    }
    #else
    init(_ ios: LiveKit.TextStreamInfo) {
        self.id = ios.id
        self.topic = ios.topic
        self.timestamp = ios.timestamp
        self.totalLength = ios.totalLength
        self.attributes = ios.attributes
        switch ios.operationType {
        case .create: self.operationType = .create
        case .update: self.operationType = .update
        case .delete: self.operationType = .delete
        case .reaction: self.operationType = .reaction
        @unknown default: self.operationType = .update
        }
        self.version = ios.version
        self.replyToStreamID = ios.replyToStreamID
        self.attachedStreamIDs = ios.attachedStreamIDs
        self.generated = ios.generated
    }
    #endif
}

public typealias TextStreamInfo = LKTextStreamInfo


