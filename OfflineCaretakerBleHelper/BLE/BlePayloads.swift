//
//  BlePayloads.swift
//  OfflineCaretakerBleHelper
//
//  Created by Chintan Dev on 4/21/26.
//

import Foundation

struct DeviceInfoPayload: Codable {
    let deviceId: String
    let deviceName: String
    let firmware: String
}

struct NetworkBootstrapPayload: Codable {
    let baseUrl: String
    let transport: String
}
