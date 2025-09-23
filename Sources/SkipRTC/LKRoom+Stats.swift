// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import livekit.org.webrtc.__
#else
import LiveKit
#endif

public struct LKStatsSnapshot {
    public let rttMs: Int64?
    public let publisherReportJson: String?
    public let subscriberReportJson: String?
}

public extension LKRoom {
    #if SKIP
    func getStatsSnapshot(completion: @escaping (LKStatsSnapshot) -> Void) {
        var pub: String? = nil
        var sub: String? = nil
        let group = java.util.concurrent.CountDownLatch(2)
        room.getPublisherRTCStats(callback: livekit.org.webrtc.RTCStatsCollectorCallback { report in
            pub = report?.toString()
            group.countDown()
        })
        room.getSubscriberRTCStats(callback: livekit.org.webrtc.RTCStatsCollectorCallback { report in
            sub = report?.toString()
            group.countDown()
        })
        _ = group.await(2, java.util.concurrent.TimeUnit.SECONDS)
        completion(LKStatsSnapshot(rttMs: nil, publisherReportJson: pub, subscriberReportJson: sub))
    }
    #else
    func getStatsSnapshot() async -> LKStatsSnapshot {
        // RTT is not publicly exposed; return nil for now. Users can compute from delegates if needed.
        return LKStatsSnapshot(rttMs: nil, publisherReportJson: nil, subscriberReportJson: nil)
    }
    #endif
}


