enum Lw005ParamAccess {
  readOnly,
  writeOnly,
  readWrite,
}

enum Lw005ParamKey {
  loraMode(0x01, Lw005ParamAccess.readWrite),
  loraDevEui(0x02, Lw005ParamAccess.readWrite),
  loraAppEui(0x03, Lw005ParamAccess.readWrite),
  loraAppKey(0x04, Lw005ParamAccess.readWrite),
  loraDevAddr(0x05, Lw005ParamAccess.readWrite),
  loraAppSkey(0x06, Lw005ParamAccess.readWrite),
  loraNwkSkey(0x07, Lw005ParamAccess.readWrite),
  loraRegion(0x08, Lw005ParamAccess.readWrite),
  loraClass(0x09, Lw005ParamAccess.readWrite),
  loraMessageType(0x0A, Lw005ParamAccess.readWrite),
  loraCh(0x0B, Lw005ParamAccess.readWrite),
  loraDutycycle(0x0C, Lw005ParamAccess.readWrite),
  loraDr(0x0D, Lw005ParamAccess.readWrite),
  loraUplinkStrategy(0x0E, Lw005ParamAccess.readWrite),
  loraMaxRetransmissionTimes(0x0F, Lw005ParamAccess.readWrite),
  loraTimeSyncInterval(0x10, Lw005ParamAccess.readWrite),
  loraNetworkCheckInterval(0x11, Lw005ParamAccess.readWrite),
  bleAdvName(0x21, Lw005ParamAccess.readWrite),
  bleAdvInterval(0x22, Lw005ParamAccess.readWrite),
  bleTxPower(0x23, Lw005ParamAccess.readWrite),
  bleConnectable(0x24, Lw005ParamAccess.readWrite),
  bleLoginMode(0x25, Lw005ParamAccess.readWrite),
  changePassword(0x26, Lw005ParamAccess.readWrite),
  powerOnDefaultMode(0x41, Lw005ParamAccess.readWrite),
  switchPayloadReportInterval(0x42, Lw005ParamAccess.readWrite),
  electricityReportInterval(0x43, Lw005ParamAccess.readWrite),
  energyConfigInterval(0x44, Lw005ParamAccess.readWrite),
  powerChangeValue(0x45, Lw005ParamAccess.readWrite),
  deviceSpecification(0x46, Lw005ParamAccess.readWrite),
  overVoltageProtection(0x47, Lw005ParamAccess.readWrite),
  sagVoltageProtection(0x48, Lw005ParamAccess.readWrite),
  overCurrentProtection(0x49, Lw005ParamAccess.readWrite),
  overLoadProtection(0x4A, Lw005ParamAccess.readWrite),
  loadNotification(0x4B, Lw005ParamAccess.readWrite),
  loadStatusThreshold(0x4C, Lw005ParamAccess.readWrite),
  powerIndicatorColor(0x4D, Lw005ParamAccess.readWrite),
  timeZone(0x4E, Lw005ParamAccess.readWrite),
  countdownReportInterval(0x4F, Lw005ParamAccess.readWrite),
  ledIndicatorStatus(0x50, Lw005ParamAccess.readWrite),
  switchStatus(0x61, Lw005ParamAccess.readOnly),
  networkStatus(0x62, Lw005ParamAccess.readOnly),
  loadStatus(0x63, Lw005ParamAccess.readOnly),
  totalEnergy(0x65, Lw005ParamAccess.readOnly),
  restart(0x66, Lw005ParamAccess.writeOnly),
  mac(0x68, Lw005ParamAccess.readOnly),
  time(0x69, Lw005ParamAccess.writeOnly),
  restore(0x6A, Lw005ParamAccess.writeOnly),
  ;

  const Lw005ParamKey(this.key, this.access);

  final int key;
  final Lw005ParamAccess access;

  bool get canRead => access != Lw005ParamAccess.writeOnly;
  bool get canWrite => access != Lw005ParamAccess.readOnly;

  bool get isControl => key >= 0x61;
}
