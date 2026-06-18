// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import Foundation
import CryptoKit
import CloudXRKit

struct ClientToServerCommand: Encodable {
    let type: String
    let message: [String: String]
}

/// Generate a UUID v5 (SHA-1, RFC 4122) from a namespace UUID and a name string.
func uuid5(namespace: UUID, name: String) -> Data {
    var namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Data($0) }
    namespaceBytes.append(Data(name.utf8))

    let hash = Data(Insecure.SHA1.hash(data: namespaceBytes))

    var result = hash.prefix(16)
    result[6] = (result[6] & 0x0F) | 0x50  // version 5
    result[8] = (result[8] & 0x3F) | 0x80  // variant RFC 4122
    return Data(result)
}

/// RFC 4122 NAMESPACE_DNS — not provided by Foundation.
let namespaceDNS = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!

/// Well-known 16-byte UUID for the teleop control message channel.
/// Matches `uuid5(NAMESPACE_DNS, "teleop_command")` used by the Isaac Lab server.
let teleopControlChannelUUID = uuid5(
    namespace: namespaceDNS,
    name: "teleop_command"
)

/// Find the teleop control channel among available channels.
/// Falls back to the first channel if no UUID match (single-channel compat).
func findTeleopChannel(in channels: [ChannelInfo]) -> ChannelInfo? {
    channels.first { $0.uuid == teleopControlChannelUUID } ?? channels.first
}
