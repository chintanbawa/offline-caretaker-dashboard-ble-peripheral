//
//  ContentView.swift
//  OfflineCaretakerBleHelper
//
//  Created by Chintan Dev on 4/21/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: BlePeripheralManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offline Caretaker BLE Helper")
                .font(.title2)
                .bold()

            Text(manager.stateText)

            Text("Advertising: \(manager.isAdvertising ? "Yes" : "No")")
            Text("Connected Centrals: \(manager.connectedCentralCount)")

            if let error = manager.lastError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }

            HStack {
                Button("Start Advertising") {
                    manager.start()
                }

                Button("Stop Advertising") {
                    manager.stop()
                }
            }
        }
        .padding()
        .frame(minWidth: 480, minHeight: 240)
    }
}

#Preview {
    ContentView(manager: BlePeripheralManager())
}
