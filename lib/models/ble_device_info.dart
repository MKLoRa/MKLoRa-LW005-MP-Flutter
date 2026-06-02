import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble/lw005_constants.dart';

String hexString(List<int> data) {
  return data
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
}

/// LW005-MP scan Service Data UUID (AD type 0x16).
const _lw005AdvServiceUuid = '0000aa04-0000-1000-8000-00805f9b34fb';

class BleDeviceInfo {
  final DeviceIdentifier id;
  final String name;
  final String macAddress;
  final int rssi;
  final int? txPowerLevel;
  final int deviceType;
  final bool passwordEnabled;
  final bool connectable;
  final double voltage;
  final double current;
  final double power;
  final int powerFactor;
  final double currentRate;
  final int loadState;
  final List<int> rawServiceData;
  final List<int> rawManufacturerData;
  final int lastScanMs;
  final int scanIntervalMs;

  BleDeviceInfo({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.rssi,
    required this.txPowerLevel,
    required this.deviceType,
    required this.passwordEnabled,
    this.connectable = true,
    this.voltage = 0,
    this.current = 0,
    this.power = 0,
    this.powerFactor = 0,
    this.currentRate = 0,
    this.loadState = 0,
    required this.rawServiceData,
    this.rawManufacturerData = const [],
    this.lastScanMs = 0,
    this.scanIntervalMs = 0,
  });

  /// MAC from AD type 0xFF response packet bytes 3-8 (0-based index 0-5).
  String get advMacAddress => macFromManufacturerData(rawManufacturerData);

  String get scanIntervalLabel =>
      scanIntervalMs == 0 ? '<->N/A' : '<->${scanIntervalMs}ms';

  String get voltageLabel => '${voltage.toStringAsFixed(1)} V';

  String get currentLabel => '${current.toStringAsFixed(3)} A';

  String get powerLabel => '${power.toStringAsFixed(1)} W';

  String get powerFactorLabel => '$powerFactor %';

  String get currentRateLabel => '${currentRate.toStringAsFixed(1)} HZ';

  String get loadStatusIconAsset {
    final state = loadState;
    if ((state & 0x04) == 0x04 ||
        (state & 0x08) == 0x08 ||
        (state & 0x10) == 0x10 ||
        (state & 0x20) == 0x20) {
      return 'assets/images/lw005_ic_overload.png';
    }
    return loadOn
        ? 'assets/images/lw005_ic_load_open.png'
        : 'assets/images/lw005_ic_load_close.png';
  }

  String get loadStatusLabel {
    if ((loadState & 0x04) == 0x04) return 'OverLoad';
    if ((loadState & 0x08) == 0x08) return 'OverCurrent';
    if ((loadState & 0x10) == 0x10) return 'SagVoltage';
    if ((loadState & 0x20) == 0x20) return 'OverVoltage';
    if ((loadState & 0x80) == 0x80) return 'ON';
    return 'OFF';
  }

  bool get loadOn => (loadState & 0x80) == 0x80;

  BleDeviceInfo copyWith({
    DeviceIdentifier? id,
    String? name,
    String? macAddress,
    int? rssi,
    int? txPowerLevel,
    int? deviceType,
    bool? passwordEnabled,
    bool? connectable,
    double? voltage,
    double? current,
    double? power,
    int? powerFactor,
    double? currentRate,
    int? loadState,
    List<int>? rawServiceData,
    List<int>? rawManufacturerData,
    int? lastScanMs,
    int? scanIntervalMs,
  }) {
    return BleDeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      rssi: rssi ?? this.rssi,
      txPowerLevel: txPowerLevel ?? this.txPowerLevel,
      deviceType: deviceType ?? this.deviceType,
      passwordEnabled: passwordEnabled ?? this.passwordEnabled,
      connectable: connectable ?? this.connectable,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      power: power ?? this.power,
      powerFactor: powerFactor ?? this.powerFactor,
      currentRate: currentRate ?? this.currentRate,
      loadState: loadState ?? this.loadState,
      rawServiceData: rawServiceData ?? this.rawServiceData,
      rawManufacturerData: rawManufacturerData ?? this.rawManufacturerData,
      lastScanMs: lastScanMs ?? this.lastScanMs,
      scanIntervalMs: scanIntervalMs ?? this.scanIntervalMs,
    );
  }

  static BleDeviceInfo mergeScanUpdate({
    required BleDeviceInfo? previous,
    required BleDeviceInfo parsed,
    required int lastScanMs,
    required int scanIntervalMs,
  }) {
    final serviceData = _preferLongerPayload(
      previous?.rawServiceData ?? const [],
      parsed.rawServiceData,
    );
    final manufacturerData = _preferLongerPayload(
      previous?.rawManufacturerData ?? const [],
      parsed.rawManufacturerData,
    );
    final mac = macFromManufacturerData(manufacturerData);
    return parsed.copyWith(
      macAddress: mac,
      rawServiceData: serviceData,
      rawManufacturerData: manufacturerData,
      lastScanMs: lastScanMs,
      scanIntervalMs: scanIntervalMs,
    );
  }

  static List<int> _preferLongerPayload(List<int> a, List<int> b) {
    if (b.length > a.length) {
      return b;
    }
    if (a.length > b.length) {
      return a;
    }
    final macA = macFromManufacturerData(a);
    final macB = macFromManufacturerData(b);
    if (macB.isNotEmpty && macA.isEmpty) {
      return b;
    }
    return a.isNotEmpty ? a : b;
  }

  static bool _isLw005AdvUuid(Guid uuid) {
    return uuid.toString().toLowerCase().contains('aa04');
  }

  /// Protocol response packet bytes 3-8 → payload indices 0-5.
  static String macFromManufacturerData(List<int> data) {
    if (data.length < 6) {
      return '';
    }
    final macBytes = data.sublist(0, 6);
    if (macBytes.every((b) => b == 0)) {
      return '';
    }
    return _macFromBytes(macBytes);
  }

  static String _macFromBytes(List<int> macBytes) {
    return macBytes
        .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  static List<int>? _lw005ServiceData(AdvertisementData adv) {
    final byUuid = adv.serviceData[Guid(_lw005AdvServiceUuid)];
    if (byUuid != null && byUuid.isNotEmpty) {
      return byUuid;
    }

    for (final entry in adv.serviceData.entries) {
      if (_isLw005AdvUuid(entry.key) && entry.value.isNotEmpty) {
        return entry.value;
      }
    }

    for (final data in adv.serviceData.values) {
      if (data.isNotEmpty) {
        return data;
      }
    }

    return null;
  }

  static List<int>? _lw005ManufacturerData(AdvertisementData adv) {
    if (adv.msd.isEmpty) {
      return null;
    }
    for (final bytes in adv.msd) {
      if (bytes.length == Lw005ProtocolConstants.advMfgPayloadLength) {
        return bytes;
      }
      if (bytes.length > Lw005ProtocolConstants.advMfgPayloadLength) {
        return bytes.sublist(bytes.length - Lw005ProtocolConstants.advMfgPayloadLength);
      }
    }
    return adv.msd.first;
  }

  static int _uint16(List<int> data, int offset) {
    if (data.length < offset + 2) {
      return 0;
    }
    return ((data[offset] & 0xFF) << 8) | (data[offset + 1] & 0xFF);
  }

  static int _int16(List<int> data, int offset) {
    final value = _uint16(data, offset);
    if (value > 0x7FFF) {
      return value - 0x10000;
    }
    return value;
  }

  static int _int32(List<int> data, int offset) {
    if (data.length < offset + 4) {
      return 0;
    }
    var value = 0;
    for (var i = 0; i < 4; i++) {
      value = (value << 8) | (data[offset + i] & 0xFF);
    }
    if (value > 0x7FFFFFFF) {
      return value - 0x100000000;
    }
    return value;
  }

  static BleDeviceInfo? fromScanResult(ScanResult result) {
    final adv = result.advertisementData;
    final serviceData = _lw005ServiceData(adv);
    final manufacturerData = _lw005ManufacturerData(adv);
    if (serviceData == null || manufacturerData == null) {
      return null;
    }
    if (manufacturerData.length != Lw005ProtocolConstants.advMfgPayloadLength) {
      return null;
    }

    final deviceType = serviceData[0] & 0xFF;
    final voltage = _uint16(manufacturerData, 6) * 0.1;
    final current = _int16(manufacturerData, 8) * 0.001;
    final power = _int32(manufacturerData, 10) * 0.1;
    final powerFactor = manufacturerData[14] & 0xFF;
    final currentRate = _uint16(manufacturerData, 15) * 0.001;
    final loadState = manufacturerData[21] & 0xFF;
    final txPower = manufacturerData[22];
    final passwordEnabled = (loadState & 0x02) == 0x02;
    final macAddress = macFromManufacturerData(manufacturerData);

    return BleDeviceInfo(
      id: result.device.remoteId,
      name: adv.advName.isNotEmpty ? adv.advName : result.device.advName,
      macAddress: macAddress,
      rssi: result.rssi,
      txPowerLevel: txPower,
      deviceType: deviceType,
      passwordEnabled: passwordEnabled,
      connectable: adv.connectable,
      voltage: voltage,
      current: current,
      power: power,
      powerFactor: powerFactor,
      currentRate: currentRate,
      loadState: loadState,
      rawServiceData: serviceData,
      rawManufacturerData: manufacturerData,
    );
  }
}
