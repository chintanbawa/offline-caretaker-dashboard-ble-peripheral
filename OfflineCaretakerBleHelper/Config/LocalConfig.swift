//
//  LocalConfig.swift
//  OfflineCaretakerBleHelper
//
//  Created by Chintan Dev on 4/21/26.
//

import Foundation

struct LocalConfig {
    let baseURL: String
    let deviceId: String
    let deviceName: String
    let firmware: String

    static func load() -> LocalConfig {
        let env = ProcessInfo.processInfo.environment

        return LocalConfig(
            baseURL: env["BOOTSTRAP_BASE_URL"] ?? "http://192.168.1.10:3000",
            deviceId: env["BLE_DEVICE_ID"] ?? "edge-node-mac-dev",
            deviceName: env["BLE_DEVICE_NAME"] ?? "Edge Node Mac Dev",
            firmware: env["BLE_FIRMWARE"] ?? "0.1.0"
        )
    }
}
