// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.participant.__
#else
import LiveKit
#endif

public extension LKRoom {
    #if SKIP
    typealias LKRpcHandler = (Any) async throws -> String

    func registerRpcMethod(_ method: String, handler: @escaping LKRpcHandler) async throws {
        room.registerRpcMethod(method: method) { data in
            return try await handler(data as Any)
        }
    }

    func unregisterRpcMethod(_ method: String) async {
        room.unregisterRpcMethod(method)
    }
    #else
    typealias LKRpcHandler = LiveKit.RpcHandler

    func registerRpcMethod(_ method: String, handler: @escaping LKRpcHandler) async throws {
        try await room.registerRpcMethod(method, handler: handler)
    }

    func unregisterRpcMethod(_ method: String) async {
        await room.unregisterRpcMethod(method)
    }
    #endif
}


