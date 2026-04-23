# Offline Caretaker BLE Peripheral Helper

A lightweight macOS Swift BLE peripheral helper for the **Offline-First React Native Caretaker Dashboard**.

This project exists to provide a nearby Bluetooth Low Energy device for local discovery and bootstrap during development. It advertises a custom BLE service, exposes readable characteristics for device metadata and network bootstrap information, and allows the React Native mobile app to discover the nearby device and fetch the simulator base URL automatically.

## Related Repositories

**Mobile App Repo:** `https://github.com/chintanbawa/offline-caretaker-dashboard-rn`

**Device Simulator Repo:** `https://github.com/chintanbawa/offline-caretaker-dashboard-simulator`

This BLE helper is meant to work alongside the React Native app and the local device simulator.

## Purpose

This project is intentionally small.

It is not pretending to be a real production hardware stack, full robotics controller, or secure device runtime.

Its job is only to provide a realistic nearby BLE peripheral for:

* local BLE discovery
* device identification
* bootstrap payload sharing
* local development and demo workflows

The actual operational data flow still happens over local Wi-Fi HTTP through the device simulator.

## Features

* Custom BLE peripheral built with Swift and CoreBluetooth
* Advertises a custom BLE service UUID
* Exposes readable characteristics for:

  * device info
  * network bootstrap
* Sends a bootstrap payload containing the simulator base URL
* Works as a local helper for the Expo React Native app
* Safe public-repo defaults using non-sensitive example values
* Local environment variable overrides for development

## Tech Stack

* Swift
* SwiftUI
* CoreBluetooth
* macOS App Sandbox Bluetooth capability

## BLE Contract

### Advertised Service

Custom service UUID:

`E2C20303-9DD5-4CBA-A51E-B738BAE57A41`

### Characteristics

#### Device Info Characteristic

UUID:

`5A87B2E3-67C7-418E-9806-C9E6A1694A28`

Readable JSON payload:

```json
{
  "deviceId": "edge-node-mac-dev",
  "deviceName": "Edge Node Mac Dev",
  "firmware": "0.1.0"
}
```

#### Network Bootstrap Characteristic

UUID:

`91823B5A-5D1A-4C23-8B39-50E868735399`

Readable JSON payload:

```json
{
  "baseUrl": "http://192.168.1.10:3000",
  "transport": "wifi-http"
}
```

## How it works with the mobile app

1. Start this BLE helper on your Mac
2. Start the local device simulator on the same network
3. Open the Expo mobile app
4. Go to the BLE Discovery screen
5. Scan for the BLE helper
6. Connect and read:

   * device info
   * network bootstrap
7. Save the returned base URL inside the mobile app
8. Continue normal operations over local Wi-Fi HTTP

## Why this exists separately from the simulator

The BLE helper is intentionally separate from the Node.js simulator because they serve different purposes:

* the BLE helper handles local discovery and bootstrap
* the simulator handles the local HTTP API and operational data
* the mobile app handles UI, persistence, sync, queueing, and audit

Keeping them separate avoids forcing BLE responsibilities into the Node.js simulator and keeps the overall design cleaner.

## Project Structure

```text
OfflineCaretakerBleHelper/
├── App/
├── BLE/
├── Config/
└── UI/
```

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/chintanbawa/offline-caretaker-dashboard-ble-peripheral
```

### 2. Open in Xcode

Open the macOS project in Xcode.

### 3. Configure Signing & Capabilities

In the target settings, enable the required capabilities:

* App Sandbox
* Hardware → Bluetooth
* Incoming Connections (if required by your working setup)

Also add the Bluetooth usage description in `Info.plist`, for example:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to advertise a local demo edge device and share bootstrap connection details.</string>
```

### 4. Configure local environment variables

In your Xcode Run Scheme, set environment variables such as:

* `BOOTSTRAP_BASE_URL`
* `BLE_DEVICE_ID`
* `BLE_DEVICE_NAME`
* `BLE_FIRMWARE`

Example values:

```text
BOOTSTRAP_BASE_URL=http://192.168.1.10:3000
BLE_DEVICE_ID=edge-node-mac-dev
BLE_DEVICE_NAME=Edge Node Mac Dev
BLE_FIRMWARE=0.1.0
```

For public repo safety, commit only example values and keep real local values in your personal local scheme.

### 5. Start the device simulator

Run the companion simulator from:

`https://github.com/chintanbawa/offline-caretaker-dashboard-simulator`

### 6. Run the BLE helper

Build and run the macOS app from Xcode.

When working correctly, the helper should:

* power on Bluetooth
* add the custom service
* start advertising
* respond to read requests from the mobile app

## Implementation Notes

* The helper uses `CBPeripheralManager`
* Characteristics are defined as dynamic readable characteristics using `value: nil`
* Read requests are handled through `didReceiveRead`
* The peripheral manager is kept active on a dedicated queue instead of being tied only to fragile UI lifecycle behavior
* Advertising starts after the service is added successfully

## Security Notes

This project is for development and demonstration only.

It does **not** claim production-grade BLE security.

Public-repo-safe guidance:

* do not commit real local IP addresses if you do not want them in git history
* do not commit real secrets, certificates, or production keys
* use fake or example values in shared schemes
* keep local overrides in unshared/local scheme settings where appropriate

## Limitations

* Development helper only
* macOS-based BLE peripheral, not real embedded hardware
* No authentication or secure pairing workflow
* No production-hardening claims
* Bootstrap only; main operational traffic still happens over Wi-Fi HTTP
* Not intended to replace real hardware or secure provisioning systems

## Related Links

* Mobile App Repo: `https://github.com/chintanbawa/offline-caretaker-dashboard-rn`
* Device Simulator Repo: `https://github.com/chintanbawa/offline-caretaker-dashboard-simulator`
* BLE Peripheral Helper Repo: `https://github.com/chintanbawa/offline-caretaker-dashboard-ble-peripheral`
