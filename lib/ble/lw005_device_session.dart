import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_device_info.dart';
import 'lw005_ble_client.dart';
import 'lw005_export_data_store.dart';
import 'lw005_protocol_api.dart';

class Lw005DeviceSession {
  Lw005DeviceSession._({
    required this.deviceInfo,
    required this.client,
    required this.protocol,
    required this.deviceInfoApi,
  });

  final BleDeviceInfo deviceInfo;
  final Lw005BleClient client;
  final Lw005ProtocolApi protocol;
  final Lw005DeviceInfoApi deviceInfoApi;
  final Lw005ExportDataStore exportData = Lw005ExportDataStore();

  static Lw005DeviceSession? _active;

  static Lw005DeviceSession? get active => _active;

  static Future<Lw005DeviceSession> connect({
    required BleDeviceInfo deviceInfo,
    String? password,
  }) async {
    final bluetoothDevice = BluetoothDevice.fromId(deviceInfo.id.str);
    final client = Lw005BleClient();

    await client.connectWithRetry(bluetoothDevice);

    if (password != null && password.isNotEmpty) {
      final verified = await client.verifyPassword(password);
      if (!verified) {
        await client.disconnect();
        throw Lw005ProtocolException('Password verification failed');
      }
    }

    final session = Lw005DeviceSession._(
      deviceInfo: deviceInfo,
      client: client,
      protocol: Lw005ProtocolApi(client),
      deviceInfoApi: Lw005DeviceInfoApi(client),
    );
    _active = session;
    return session;
  }

  Future<void> disconnect() async {
    await client.disconnect();
    clearActiveIfMatches(this);
  }

  static void clearActiveIfMatches(Lw005DeviceSession session) {
    if (_active == session) {
      _active = null;
    }
  }
}
