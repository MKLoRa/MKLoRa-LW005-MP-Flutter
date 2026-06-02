# MKLoRa LW005-MP Flutter

Flutter client for **LW005-MP** smart power meter / switch devices. Supports BLE scanning, connection, protocol parameter read/write, device-initiated disconnect notifications, LoRa connection and application settings, General tab (switch / electricity / energy / protection / load / countdown / LED), BLE advertising settings, debug log export, and Nordic DFU firmware updates on Android and iOS physical devices.

Native Android reference: [`LW005-MP-Android`](../LW005-MP-Android)

---

## Requirements

- Flutter SDK `^3.12.0`
- Android / iOS **physical device** (simulators do not support BLE)
- iOS: grant Bluetooth permission on first launch; run `pod install` in `ios/` when using CocoaPods

---

## Quick Start

```bash
flutter pub get
flutter run
```

The app opens on the scan page. Tap **CONNECT** on a device to connect and open the detail page.

---

## Project Structure

```
lib/
├── ble/                         # BLE connection and LW005-MP protocol layer
│   ├── lw005_ble_client.dart          # Connect, read/write frames, Notify handling
│   ├── lw005_protocol_api.dart        # Generic readParam / writeParam
│   ├── lw005_protocol_named_api.dart  # Named helpers (readLoraMode, writeSwitchStatus, …)
│   ├── lw005_param_key.dart           # Parameter keys (ParamsKeyEnum / ControlKeyEnum mirror)
│   ├── lw005_param_helpers.dart       # Byte helpers + syncTime()
│   ├── lw005_data_codec.dart          # LoRa / uplink strategy encode-decode
│   ├── lw005_general_param_codec.dart # General settings composite payloads
│   ├── lw005_lora_conn_helpers.dart   # LoRa Class A/C, region helpers
│   ├── lw005_option_lists.dart        # Picker option lists (region, DR, …)
│   ├── lw005_device_session.dart      # Session wrapper (connection + API entry)
│   ├── lw005_disconnect_event.dart    # Disconnect notify parse
│   ├── lw005_debug_log_file.dart      # Debug log file persistence
│   ├── lw005_export_data_store.dart   # In-memory export cache (reserved)
│   ├── lw005_tracked_file.dart        # tracked.txt helper (reserved)
│   └── lw005_constants.dart           # GATT UUIDs and protocol constants
├── dfu/                         # Nordic DFU upgrade
├── models/                      # Scan result models (BleDeviceInfo)
├── viewmodels/                  # Scan page ViewModel
└── ui/                          # Pages and widgets
    └── pages/
        ├── ble_scan_page.dart
        ├── device_detail_page.dart
        └── device_detail/       # LoRa / General / BLE / Device tabs & sub-pages
packages/
└── nordic_dfu/                  # Local fork with Android disableMtuRequest support
```

---

## 1. Scanning for Devices

Scanning is handled by `BleScanViewModel` via `flutter_blue_plus`, filtering LW005-MP advertisements by Service Data UUID `0000aa04-0000-1000-8000-00805f9b34fb`.

Manufacturer data (AD type 0xFF, **23 bytes** payload) and Service Data are both required. Parsed fields (aligned with native `BeaconInfoParseableImpl` / `BleDeviceInfo`):

| Field | Source |
|-------|--------|
| `deviceType` | Service Data byte 0 |
| `passwordEnabled` | Manufacturer byte 21, bit 1 (`0x02`) |
| `voltage` | Manufacturer bytes 6–7 × 0.1 V |
| `current` | Manufacturer bytes 8–9 × 0.001 A (signed) |
| `power` | Manufacturer bytes 10–13 × 0.1 W (signed) |
| `powerFactor` | Manufacturer byte 14 |
| `currentRate` | Manufacturer bytes 15–16 × 0.001 Hz |
| `loadState` | Manufacturer byte 21 (ON/OFF, protection flags) |
| `txPowerLevel` | Manufacturer byte 22 |
| `macAddress` | Manufacturer bytes **0–5** (protocol response packet bytes 3–8; used for display and Android DFU) |
| `scanIntervalMs` | Derived from successive advertisement timestamps |

Scan list UI follows native `lw005_list_item_device.xml` (voltage, current, power, power factor, current rate, load status).

### Usage

```dart
final vm = BleScanViewModel();
await vm.init(context);
await vm.startScan(context: context, clearDevices: true);
vm.stopScan();

final devices = vm.filteredDevices;   // Sorted by RSSI
await vm.applyFilter(context: context, keyword: 'LW005', rssiDbm: -80);
```

### Scan Result Model

```dart
for (final device in vm.filteredDevices) {
  print(device.name);
  print(device.advMacAddress);
  print('${device.rssi} dBm');
  print(device.scanIntervalLabel);    // "<->N/A" or "<->1234ms"
  print(device.passwordEnabled);
  print(device.deviceType);
  print(device.voltageLabel);         // e.g. "220.5 V"
  print(device.currentLabel);
  print(device.powerLabel);
  print(device.loadStatusLabel);      // ON / OFF / OverLoad / …
}
```

---

## 2. Connecting to a Device

Scanning stops before connecting. A GATT connection is established and the password is verified when required. Returns a `Lw005DeviceSession`.

```dart
import 'package:lw005_mp_flutter/ble/lw005.dart';

final device = vm.filteredDevices.first;

final session = await vm.connectDevice(
  context: context,
  device: device,
  password: device.passwordEnabled ? '123456' : null,
);

// Or use the lower-level API directly
final session = await Lw005DeviceSession.connect(
  deviceInfo: device,
  password: '123456',
);
```

After a successful connection:

| Member | Description |
|--------|-------------|
| `session.protocol` | Parameter read/write API |
| `session.deviceInfoApi` | Standard Device Information characteristics |
| `session.client.disconnectEvents` | Device-initiated disconnect notifications (AA01) |
| `session.client.logNotifyEvents` | Debug log notify stream (AA05) |

Connection details (`Lw005BleClient.connectWithRetry`):

- Up to 5 retries, 50 s total timeout
- Android requests MTU 247; iOS negotiates MTU automatically
- Subscribes password, disconnect, params, and control Notify on connect
- Waits 500 ms after connect before sending protocol frames

Entering the detail page automatically calls `protocol.syncTime()` (UTC epoch seconds, control key `0x69` / `time`).

---

## 3. Reading and Writing Protocol Parameters

Frame format: `ED [flag] [cmd] [len] [data…]`

- `flag=0x00` read, `flag=0x01` write, `flag=0x02` notify
- Params channel (AA02): keys `< 0x61`
- Control channel (AA03): keys `>= 0x61`
- Multi-packet responses use head `0xEE` and are reassembled automatically

Parameter keys are defined in `lib/ble/lw005_param_key.dart` (mirror of native `ParamsKeyEnum` / `ControlKeyEnum`).

### 3.1 Named API (Recommended)

`Lw005ProtocolNamedReadApi` / `Lw005ProtocolNamedWriteApi` extensions on `Lw005ProtocolApi`:

```dart
final api = session.protocol;

// Read LoRa mode (ABP=1, OTAA=2)
final mode = await api.readLoraMode();
print(Lw005ParamHelpers.uint8(mode.data));

// Read switch status (control 0x61)
final switchStatus = await api.readSwitchStatus();

// Read LoRa Class (0=Class A, 2=Class C)
final loraClass = await api.readLoraClass();

// Write electricity report interval (uint16, seconds)
await api.writeElectricityReportInterval(
  Lw005ParamHelpers.uint16Bytes(60),
);

// Write switch ON + interval + power-on mode (Switch Control page)
await api.writeSwitchStatus([1]);
await api.writeSwitchPayloadReportInterval(Lw005ParamHelpers.uint16Bytes(30));
await api.writePowerOnDefaultMode([0]); // 0=Off, 1=On, 2=Restore Last Mode

// Sync UTC time (also called on detail page entry)
final synced = await api.syncTime();

// Factory reset / reboot
await api.writeRestoreEmpty();
await api.writeRestartEmpty();
```

Integer payloads use **big-endian** byte order (`Lw005ParamHelpers.int32Bytes`, `uint16Bytes`, `bytesToInt`), matching native `MokoUtils.toInt` / `toByteArray`.

Composite General payloads (energy config, load notification, protection, LED, power indicator color) are built via `Lw005GeneralParamCodec`.

### 3.2 Generic API

```dart
final result = await api.readParam(Lw005ParamKey.bleTxPower);
final txPower = Lw005ParamHelpers.byte0(result.data);

await api.writeParam(
  Lw005ParamKey.countdownReportInterval,
  [30], // single byte, 10~60 s
);
```

### 3.3 GATT Device Information

```dart
final info = session.deviceInfoApi;
final model = await info.readModelNumber();
final firmware = await info.readFirmwareRevision();
final serial = await info.readSerialNumber();
```

### 3.4 Return Values

| Type | Field | Description |
|------|-------|-------------|
| `Lw005ParamResult` | `data` | Parsed payload bytes |
| | `raw` | Full frame returned by the device |
| | `key` | Parameter command byte |
| `writeParam` | returns `bool` | `true` when write ACK byte is `0x01` |

Common parsing helpers: `Lw005ParamHelpers.uint8`, `uint16`, `int32`, `bytesToInt`, `bytesToString`, `formatMac`, etc.

---

## 4. Receiving Data (Notify)

Device responses and push data are delivered via BLE Notify. `Lw005BleClient` matches incoming frames to pending requests and completes the corresponding `Future`.

### 4.1 Protocol Responses (AA02 params / AA03 control)

Each `readParam` / `writeParam` call:

1. Writes a request frame to the params or control characteristic
2. Waits for a Notify response with the same key
3. Reassembles multi-packet responses when `head=0xEE`

You do not need to subscribe to the params/control characteristics manually.

### 4.2 Disconnect Notifications (AA01)

```dart
session.client.disconnectEvents.listen((event) {
  print('type=${event.type}');
  print(event.message);
  // 1=password timeout  2=password changed  3=3-min idle
  // 4=reboot  5=factory reset
});
```

Example raw notify frame: `ED 02 01 01 04` → type 4, device rebooted.

The detail page handles this globally: a dialog is shown and the user is returned to the scan page.

### 4.3 Debug Log (AA05)

**Device tab → System Information → Debugger Mode** enables log Notify on **Start**, streams `logNotifyEvents`, and saves text under `{appDocuments}/LW005/logs/{mac}/` (up to 10 files). Log characteristic is resolved across all GATT services after each `discoverServices`.

```dart
await session.client.enableLogNotify();
session.client.logNotifyEvents.listen((chunk) {
  print(chunk);
});
await session.client.disableLogNotify();
```

---

## 5. Disconnecting

### Manual Disconnect

```dart
await session.disconnect();
await vm.disconnectDevice();
await vm.onReturnedFromDetail(context);   // Disconnect + clear list and rescan
```

### Unexpected Disconnect

When the device sends a disconnect Notify or the BLE link drops, `disconnectEvents` emits an event. The detail page shows a dialog, calls `session.disconnect()`, and returns to the scan page.

Disconnect events are ignored during DFU to avoid false dialogs.

---

## 6. DFU Firmware Update

UI entry: **Device tab → System Information → DFU**

Flow (`Lw005DfuService` + local `packages/nordic_dfu`):

1. User selects a `.zip` firmware package
2. Chip MAC is read from params (`0x68`); current GATT connection is closed
3. DFU progress dialog is shown
4. Nordic DFU starts (Android uses chip MAC; iOS uses CoreBluetooth peripheral UUID)
5. Success: *Update firmware successfully! Please reconnect the device.* → return to scan page
6. Failure: error shown via SnackBar

```dart
import 'package:lw005_mp_flutter/dfu/lw005_dfu_coordinator.dart';
import 'package:lw005_mp_flutter/dfu/lw005_dfu_service.dart';

Lw005DfuCoordinator.begin(mac: chipMac);
await session.disconnect();

await Lw005DfuService.start(
  address: dfuAddress,
  filePath: '/path/to/firmware.zip',
  deviceType: device.deviceType,
  onStatus: (status) => print(status),
  onProgress: (percent) => print('$percent%'),
);

Lw005DfuCoordinator.end();
```

Notes:

- Firmware package must be a **ZIP** file
- Do not rely on the original GATT session during DFU; the device reboots when done
- **Android only** — MTU behaviour follows native `SystemInfoActivity` by `deviceType`:
  - `deviceType == 0`: `disableMtuRequest()`
  - `deviceType == 1`: `setCurrentMtu(247)`
- iOS does not apply Android MTU settings
- Swift Package Manager is disabled in `pubspec.yaml` (`enable-swift-package-manager: false`) to use the CocoaPods NordicDFU build on iOS

---

## 7. Debug Protocol Logging

In debug builds, the console prints all TX/RX frames:

```
[LW005 TX] params | READ loraMode (0x01) | frame=ED 00 01 00
[LW005 RX] params | loraMode (0x01) | frame=ED 00 01 01 02 | data=02
```

Disable logging:

```dart
Lw005ProtocolLogger.enabled = false;
```

---

## 8. Permissions

| Platform | Permissions |
|----------|-------------|
| Android | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, location (required for scanning) |
| iOS | `NSBluetoothAlwaysUsageDescription` (configured in `Info.plist`) |

---

## 10. Typical Flow

```
Scan page
  └─ startScan → device list (Service Data AA04 + manufacturer 0xFF, 23 bytes)
  └─ connectDevice → Lw005DeviceSession
       └─ Detail page (LoRa / General / BLE / Device tabs)
            ├─ syncTime() on entry → "Time sync completed!"
            ├─ protocol.readXxx / writeXxx
            ├─ General → Switch Control / Electricity / Energy / Protection / …
            ├─ logNotifyEvents → Debugger Mode Start/Stop
            ├─ disconnectEvents → dialog → back to scan page
            └─ DFU → pick zip → upgrade → back to scan page
```

---

## Repository

- GitHub: [MKLoRa/MKLoRa-LW005-MP-Flutter](https://github.com/MKLoRa/MKLoRa-LW005-MP-Flutter)
