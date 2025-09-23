// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation

public struct ReceivedMessage: Sendable {
    public let topic: String?
    public let text: String?
    public let data: Data?
    public let participantIdentity: Participant.Identity?

    public init(topic: String?, text: String?, data: Data?, participantIdentity: Participant.Identity?) {
        self.topic = topic
        self.text = text
        self.data = data
        self.participantIdentity = participantIdentity
    }
}


