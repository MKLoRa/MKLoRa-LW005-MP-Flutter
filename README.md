# MKLoRa LW005-MP Flutter

Flutter client for **LW005-MP** smart power meter / switch devices.

Native Android reference: `LW005-MP-Android`

## Highlights

- BLE scan filtered by Service Data UUID `0000aa04-0000-1000-8000-00805f9b34fb`
- Scan list MAC from manufacturer response packet bytes 3–8 (iOS compatible)
- LoRa / General / Device / BLE configuration aligned with LW005-MP protocol
- Nordic DFU firmware update on Android and iOS

## Package

- Dart: `lw005_mp_flutter`
- Android: `com.moko.ft.lw005mp`
- App name: `LW005MP_Flutter`
