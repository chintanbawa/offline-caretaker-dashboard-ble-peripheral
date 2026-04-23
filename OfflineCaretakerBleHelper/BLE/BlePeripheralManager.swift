//
//  BlePeripheralManager.swift
//  OfflineCaretakerBleHelper
//
//  Created by Chintan Dev on 4/21/26.
//

internal import Combine
import CoreBluetooth
import Foundation

@MainActor
final class BlePeripheralManager: NSObject, ObservableObject {
    @Published var stateText: String = "Initializing..."
    @Published var isAdvertising: Bool = false
    @Published var lastError: String?
    @Published var connectedCentralCount: Int = 0

    private let config: LocalConfig
    private var peripheralManager: CBPeripheralManager!
    private let bleQueue = DispatchQueue(
        label: "com.chintanbawa.OfflineCaretakerBleHelper.ble.queue",
        qos: .userInitiated
    )

    private var deviceInfoCharacteristic: CBMutableCharacteristic?
    private var networkBootstrapCharacteristic: CBMutableCharacteristic?
    
    // Cache to store data for multi-part (offset) reads
    private var currentReadData: Data?

    init(config: LocalConfig = .load()) {
        self.config = config
        super.init()
        // Create the manager AFTER super.init so 'self' is fully ready
        self.peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: bleQueue,
            options: [
                CBPeripheralManagerOptionRestoreIdentifierKey: "OfflineCaretakerRestoreID"
            ]
        )
    }

    func start() {
        guard peripheralManager.state == .poweredOn else {
            stateText = "Bluetooth not ready: \(describeState(peripheralManager.state))"
            return
        }
        setupServices()
    }

    func stop() {
        peripheralManager.stopAdvertising()
        isAdvertising = false
    }

    private func setupServices() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()

        let deviceInfo = CBMutableCharacteristic(
            type: CBUUID(string: BleConstants.deviceInfoUUID),
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )

        let networkBootstrap = CBMutableCharacteristic(
            type: CBUUID(string: BleConstants.networkBootstrapUUID),
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )

        self.deviceInfoCharacteristic = deviceInfo
        self.networkBootstrapCharacteristic = networkBootstrap

        let service = CBMutableService(
            type: CBUUID(string: BleConstants.serviceUUID),
            primary: true
        )
        service.characteristics = [deviceInfo, networkBootstrap]
        peripheralManager.add(service)
    }

    private func startAdvertising() {
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: BleConstants.advertisedName,
            CBAdvertisementDataServiceUUIDsKey: [
                CBUUID(string: BleConstants.serviceUUID)
            ],
        ])
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        // Keeping it compact for BLE efficiency
        return try encoder.encode(value)
    }

    private func describeState(_ state: CBManagerState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "poweredOff"
        case .poweredOn: return "poweredOn"
        @unknown default: return "unknown-default"
        }
    }
}

extension BlePeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let newState = "Bluetooth state: \(describeState(peripheral.state))"
        let poweredOn = peripheral.state == .poweredOn

        Task { @MainActor in
            self.stateText = newState
            if poweredOn {
                self.start()
            } else {
                self.isAdvertising = false
            }
        }
    }

    func peripheralManager( _ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error? ) {
        if let error {
            Task { @MainActor in
                self.lastError = "Failed to add service: \(error.localizedDescription)"
            }
            return
        }
        startAdvertising()
    }

    func peripheralManager( _ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any] ) {
        print("Core Bluetooth is restoring the peripheral state.")
    }

    func peripheralManagerDidStartAdvertising( _ peripheral: CBPeripheralManager, error: Error? ) {
        Task { @MainActor in
            if let error {
                self.lastError = "Advertising failed: \(error.localizedDescription)"
                self.isAdvertising = false
            } else {
                self.isAdvertising = true
                self.lastError = nil
            }
        }
    }

    func peripheralManager( _ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest ) {
        // If offset is 0, this is the start of a new read operation.
        // We generate the data once and cache it to ensure consistency during multi-part reads.
        if request.offset == 0 {
            do {
                let uuidString = request.characteristic.uuid.uuidString.lowercased()
                if uuidString == BleConstants.deviceInfoUUID.lowercased() {
                    currentReadData = try encode(DeviceInfoPayload(
                        deviceId: config.deviceId,
                        deviceName: config.deviceName,
                        firmware: config.firmware
                    ))
                } else if uuidString == BleConstants.networkBootstrapUUID.lowercased() {
                    currentReadData = try encode(NetworkBootstrapPayload(
                        baseUrl: config.baseURL,
                        transport: "wifi-http"
                    ))
                } else {
                    peripheral.respond(to: request, withResult: .attributeNotFound)
                    return
                }
            } catch {
                let errorMsg = error.localizedDescription
                Task { @MainActor in self.lastError = "Encoding failed: \(errorMsg)" }
                peripheral.respond(to: request, withResult: .unlikelyError)
                return
            }
        }

        // Use the cached data to fulfill the request
        guard let data = currentReadData else {
            peripheral.respond(to: request, withResult: .unlikelyError)
            return
        }

        if request.offset > data.count {
            peripheral.respond(to: request, withResult: .invalidOffset)
            return
        }

        // Determine the slice of data to send based on the offset
        let remainingData = data.subdata(in: request.offset..<data.count)
        request.value = remainingData
        
        peripheral.respond(to: request, withResult: .success)
        
        if let chunkString = String(data: remainingData, encoding: .utf8) {
            print("!!! READ REQUEST !!! UUID: \(request.characteristic.uuid.uuidString) Offset: \(request.offset)")
            print("Sending Chunk: \(chunkString)")
        }
    }
}
