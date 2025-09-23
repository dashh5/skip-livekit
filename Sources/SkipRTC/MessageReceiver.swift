// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation

public final class MessageReceiver: @unchecked Sendable {
    private var onMessage: @Sendable (ReceivedMessage) -> Void
    private var onClose: @Sendable (Error?) -> Void

    public init(onMessage: @escaping @Sendable (ReceivedMessage) -> Void,
                onClose: @escaping @Sendable (Error?) -> Void = { _ in }) {
        self.onMessage = onMessage
        self.onClose = onClose
    }

    // Bridge from LKRoom handlers
    func handleText(reader: LKTextStreamReader, identity: Participant.Identity, topic: String?) {
        Task {
            let text = try? await reader.readAll()
            self.onMessage(ReceivedMessage(topic: topic, text: text, data: nil, participantIdentity: identity))
        }
    }

    func handleBytes(reader: LKByteStreamReader, identity: Participant.Identity, topic: String?) {
        Task {
            let data = try? await reader.readAll()
            self.onMessage(ReceivedMessage(topic: topic, text: nil, data: data, participantIdentity: identity))
        }
    }

    func handleClose(_ error: Error?) {
        onClose(error)
    }
}


