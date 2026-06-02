import 'lw005_ble_client.dart';
import 'lw005_param_key.dart';

class Lw005ProtocolApi {
  Lw005ProtocolApi(this._client);

  final Lw005BleClient _client;

  Lw005BleClient get client => _client;

  Future<bool> verifyPassword(String password) {
    return _client.verifyPassword(password);
  }

  Future<Lw005ParamResult> readParam(
    Lw005ParamKey key, {
    Lw005ParamChannel? channel,
    bool packet = false,
  }) {
    if (!key.canRead) {
      throw Lw005ProtocolException('Parameter ${key.name} is write-only');
    }
    return _client.readParam(
      key: key.key,
      channel: channel ?? _channelForKey(key),
      packet: packet,
    );
  }

  Future<bool> writeParam(
    Lw005ParamKey key,
    List<int> data, {
    Lw005ParamChannel? channel,
    bool packet = false,
    int packetCount = 1,
    int packetIndex = 0,
  }) {
    if (!key.canWrite) {
      throw Lw005ProtocolException('Parameter ${key.name} is read-only');
    }
    return _client.writeParam(
      key: key.key,
      data: data,
      channel: channel ?? _channelForKey(key),
      packet: packet,
      packetCount: packetCount,
      packetIndex: packetIndex,
    );
  }

  Lw005ParamChannel _channelForKey(Lw005ParamKey key) {
    return key.isControl ? Lw005ParamChannel.control : Lw005ParamChannel.params;
  }
}

class Lw005DeviceInfoApi {
  Lw005DeviceInfoApi(this._client);

  final Lw005BleClient _client;

  Future<String> readModelNumber() => _client.readModelNumber();
  Future<String> readSerialNumber() => _client.readSerialNumber();
  Future<String> readFirmwareRevision() => _client.readFirmwareRevision();
  Future<String> readHardwareRevision() => _client.readHardwareRevision();
  Future<String> readSoftwareRevision() => _client.readSoftwareRevision();
  Future<String> readManufacturerName() => _client.readManufacturerName();
}
