import 'lw005_ble_client.dart';
import 'lw005_param_key.dart';
import 'lw005_protocol_api.dart';

extension Lw005ProtocolNamedReadApi on Lw005ProtocolApi {
  Future<Lw005ParamResult> readLoraMode() => readParam(Lw005ParamKey.loraMode);
  Future<Lw005ParamResult> readLoraDevEui() => readParam(Lw005ParamKey.loraDevEui);
  Future<Lw005ParamResult> readLoraAppEui() => readParam(Lw005ParamKey.loraAppEui);
  Future<Lw005ParamResult> readLoraAppKey() => readParam(Lw005ParamKey.loraAppKey);
  Future<Lw005ParamResult> readLoraDevAddr() => readParam(Lw005ParamKey.loraDevAddr);
  Future<Lw005ParamResult> readLoraAppSkey() => readParam(Lw005ParamKey.loraAppSkey);
  Future<Lw005ParamResult> readLoraNwkSkey() => readParam(Lw005ParamKey.loraNwkSkey);
  Future<Lw005ParamResult> readLoraRegion() => readParam(Lw005ParamKey.loraRegion);
  Future<Lw005ParamResult> readLoraClass() => readParam(Lw005ParamKey.loraClass);
  Future<Lw005ParamResult> readLoraMessageType() => readParam(Lw005ParamKey.loraMessageType);
  Future<Lw005ParamResult> readLoraMaxRetransmissionTimes() =>
      readParam(Lw005ParamKey.loraMaxRetransmissionTimes);
  Future<Lw005ParamResult> readLoraCh() => readParam(Lw005ParamKey.loraCh);
  Future<Lw005ParamResult> readLoraDr() => readParam(Lw005ParamKey.loraDr);
  Future<Lw005ParamResult> readLoraUplinkStrategy() => readParam(Lw005ParamKey.loraUplinkStrategy);
  Future<Lw005ParamResult> readLoraDutycycle() => readParam(Lw005ParamKey.loraDutycycle);
  Future<Lw005ParamResult> readLoraTimeSyncInterval() => readParam(Lw005ParamKey.loraTimeSyncInterval);
  Future<Lw005ParamResult> readLoraNetworkCheckInterval() =>
      readParam(Lw005ParamKey.loraNetworkCheckInterval);
  Future<Lw005ParamResult> readLoraNetworkStatus() => readParam(Lw005ParamKey.networkStatus);

  Future<Lw005ParamResult> readBleAdvName() => readParam(Lw005ParamKey.bleAdvName);
  Future<Lw005ParamResult> readBleAdvInterval() => readParam(Lw005ParamKey.bleAdvInterval);
  Future<Lw005ParamResult> readBleConnectable() => readParam(Lw005ParamKey.bleConnectable);
  Future<Lw005ParamResult> readBleLoginMode() => readParam(Lw005ParamKey.bleLoginMode);
  Future<Lw005ParamResult> readBleTxPower() => readParam(Lw005ParamKey.bleTxPower);

  Future<Lw005ParamResult> readPowerOnDefaultMode() => readParam(Lw005ParamKey.powerOnDefaultMode);
  Future<Lw005ParamResult> readSwitchPayloadReportInterval() =>
      readParam(Lw005ParamKey.switchPayloadReportInterval);
  Future<Lw005ParamResult> readElectricityReportInterval() =>
      readParam(Lw005ParamKey.electricityReportInterval);
  Future<Lw005ParamResult> readEnergyConfigInterval() => readParam(Lw005ParamKey.energyConfigInterval);
  Future<Lw005ParamResult> readPowerChangeValue() => readParam(Lw005ParamKey.powerChangeValue);
  Future<Lw005ParamResult> readDeviceSpecification() => readParam(Lw005ParamKey.deviceSpecification);
  Future<Lw005ParamResult> readOverVoltageProtection() =>
      readParam(Lw005ParamKey.overVoltageProtection);
  Future<Lw005ParamResult> readSagVoltageProtection() => readParam(Lw005ParamKey.sagVoltageProtection);
  Future<Lw005ParamResult> readOverCurrentProtection() =>
      readParam(Lw005ParamKey.overCurrentProtection);
  Future<Lw005ParamResult> readOverLoadProtection() => readParam(Lw005ParamKey.overLoadProtection);
  Future<Lw005ParamResult> readLoadNotification() => readParam(Lw005ParamKey.loadNotification);
  Future<Lw005ParamResult> readLoadStatusThreshold() => readParam(Lw005ParamKey.loadStatusThreshold);
  Future<Lw005ParamResult> readPowerIndicatorColor() => readParam(Lw005ParamKey.powerIndicatorColor);
  Future<Lw005ParamResult> readTimeZone() => readParam(Lw005ParamKey.timeZone);
  Future<Lw005ParamResult> readCountdownReportInterval() =>
      readParam(Lw005ParamKey.countdownReportInterval);
  Future<Lw005ParamResult> readLedIndicatorStatus() => readParam(Lw005ParamKey.ledIndicatorStatus);

  Future<Lw005ParamResult> readSwitchStatus() => readParam(Lw005ParamKey.switchStatus);
  Future<Lw005ParamResult> readLoadStatus() => readParam(Lw005ParamKey.loadStatus);
  Future<Lw005ParamResult> readTotalEnergy() => readParam(Lw005ParamKey.totalEnergy);
  Future<Lw005ParamResult> readChipMac() => readParam(Lw005ParamKey.mac);

  Future<Lw005ParamResult> readAdvName() => readBleAdvName();
  Future<Lw005ParamResult> readAdvTxPower() => readBleTxPower();
  Future<Lw005ParamResult> readPasswordVerifyEnable() => readBleLoginMode();
}

extension Lw005ProtocolNamedWriteApi on Lw005ProtocolApi {
  Future<bool> writeLoraMode(List<int> data) => writeParam(Lw005ParamKey.loraMode, data);
  Future<bool> writeLoraDevEui(List<int> data) => writeParam(Lw005ParamKey.loraDevEui, data);
  Future<bool> writeLoraAppEui(List<int> data) => writeParam(Lw005ParamKey.loraAppEui, data);
  Future<bool> writeLoraAppKey(List<int> data) => writeParam(Lw005ParamKey.loraAppKey, data);
  Future<bool> writeLoraDevAddr(List<int> data) => writeParam(Lw005ParamKey.loraDevAddr, data);
  Future<bool> writeLoraAppSkey(List<int> data) => writeParam(Lw005ParamKey.loraAppSkey, data);
  Future<bool> writeLoraNwkSkey(List<int> data) => writeParam(Lw005ParamKey.loraNwkSkey, data);
  Future<bool> writeLoraRegion(List<int> data) => writeParam(Lw005ParamKey.loraRegion, data);
  Future<bool> writeLoraClass(List<int> data) => writeParam(Lw005ParamKey.loraClass, data);
  Future<bool> writeLoraMessageType(List<int> data) =>
      writeParam(Lw005ParamKey.loraMessageType, data);
  Future<bool> writeLoraMaxRetransmissionTimes(List<int> data) =>
      writeParam(Lw005ParamKey.loraMaxRetransmissionTimes, data);
  Future<bool> writeLoraCh(List<int> data) => writeParam(Lw005ParamKey.loraCh, data);
  Future<bool> writeLoraDr(List<int> data) => writeParam(Lw005ParamKey.loraDr, data);
  Future<bool> writeLoraUplinkStrategy(List<int> data) =>
      writeParam(Lw005ParamKey.loraUplinkStrategy, data);
  Future<bool> writeLoraDutycycle(List<int> data) => writeParam(Lw005ParamKey.loraDutycycle, data);
  Future<bool> writeLoraTimeSyncInterval(List<int> data) =>
      writeParam(Lw005ParamKey.loraTimeSyncInterval, data);
  Future<bool> writeLoraNetworkCheckInterval(List<int> data) =>
      writeParam(Lw005ParamKey.loraNetworkCheckInterval, data);

  Future<bool> writeBleAdvName(List<int> data) => writeParam(Lw005ParamKey.bleAdvName, data);
  Future<bool> writeBleAdvInterval(List<int> data) => writeParam(Lw005ParamKey.bleAdvInterval, data);
  Future<bool> writeBleConnectable(List<int> data) => writeParam(Lw005ParamKey.bleConnectable, data);
  Future<bool> writeBleLoginMode(List<int> data) => writeParam(Lw005ParamKey.bleLoginMode, data);
  Future<bool> writeBleTxPower(List<int> data) => writeParam(Lw005ParamKey.bleTxPower, data);

  Future<bool> writePowerOnDefaultMode(List<int> data) => writeParam(Lw005ParamKey.powerOnDefaultMode, data);
  Future<bool> writeSwitchPayloadReportInterval(List<int> data) =>
      writeParam(Lw005ParamKey.switchPayloadReportInterval, data);
  Future<bool> writeElectricityReportInterval(List<int> data) =>
      writeParam(Lw005ParamKey.electricityReportInterval, data);
  Future<bool> writeEnergyConfigInterval(List<int> data) =>
      writeParam(Lw005ParamKey.energyConfigInterval, data);
  Future<bool> writePowerChangeValue(List<int> data) => writeParam(Lw005ParamKey.powerChangeValue, data);
  Future<bool> writeDeviceSpecification(List<int> data) =>
      writeParam(Lw005ParamKey.deviceSpecification, data);
  Future<bool> writeOverVoltageProtection(List<int> data) =>
      writeParam(Lw005ParamKey.overVoltageProtection, data);
  Future<bool> writeSagVoltageProtection(List<int> data) =>
      writeParam(Lw005ParamKey.sagVoltageProtection, data);
  Future<bool> writeOverCurrentProtection(List<int> data) =>
      writeParam(Lw005ParamKey.overCurrentProtection, data);
  Future<bool> writeOverLoadProtection(List<int> data) =>
      writeParam(Lw005ParamKey.overLoadProtection, data);
  Future<bool> writeLoadNotification(List<int> data) => writeParam(Lw005ParamKey.loadNotification, data);
  Future<bool> writeLoadStatusThreshold(List<int> data) =>
      writeParam(Lw005ParamKey.loadStatusThreshold, data);
  Future<bool> writePowerIndicatorColor(List<int> data) =>
      writeParam(Lw005ParamKey.powerIndicatorColor, data);
  Future<bool> writeTimeZone(List<int> data) => writeParam(Lw005ParamKey.timeZone, data);
  Future<bool> writeCountdownReportInterval(List<int> data) =>
      writeParam(Lw005ParamKey.countdownReportInterval, data);
  Future<bool> writeLedIndicatorStatus(List<int> data) =>
      writeParam(Lw005ParamKey.ledIndicatorStatus, data);

  Future<bool> writeRestoreEmpty() => writeParam(Lw005ParamKey.restore, const []);
  Future<bool> writeResetEmpty() => writeRestoreEmpty();
  Future<bool> writeRestartEmpty() => writeParam(Lw005ParamKey.restart, const []);

  Future<bool> writeAdvName(List<int> data) => writeBleAdvName(data);
  Future<bool> writeAdvTxPower(List<int> data) => writeBleTxPower(data);
  Future<bool> writePasswordVerifyEnable(List<int> data) => writeBleLoginMode(data);
  Future<bool> changePassword(List<int> data) => writeParam(Lw005ParamKey.changePassword, data);
}
