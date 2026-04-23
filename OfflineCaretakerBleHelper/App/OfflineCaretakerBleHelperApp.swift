//
//  OfflineCaretakerBleHelperApp.swift
//  OfflineCaretakerBleHelper
//
//  Created by Chintan Dev on 4/21/26.
//

import SwiftUI

@main
struct OfflineCaretakerBleHelperApp: App {
    @StateObject private var bleManager = BlePeripheralManager()

    var body: some Scene {
        WindowGroup {
            ContentView(manager: bleManager)
        }
    }
}
