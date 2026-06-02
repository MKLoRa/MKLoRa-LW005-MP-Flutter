import 'lw005_param_helpers.dart';

class Lw005GeneralParamCodec {
  Lw005GeneralParamCodec._();

  static List<int> energyConfigInterval(int reportInterval, int saveInterval) =>
      [saveInterval & 0xFF, reportInterval & 0xFF];

  static ({int reportInterval, int saveInterval}) parseEnergyConfigInterval(
    List<int> data,
  ) {
    if (data.length < 2) {
      return (reportInterval: 1, saveInterval: 1);
    }
    return (reportInterval: data[1], saveInterval: data[0]);
  }

  static List<int> ledIndicatorStatus({
    required bool networkIndicator,
    required bool powerIndicator,
  }) =>
      [
        powerIndicator ? 1 : 0,
        networkIndicator ? 1 : 0,
      ];

  static ({bool networkIndicator, bool powerIndicator}) parseLedIndicatorStatus(
    List<int> data,
  ) {
    if (data.length < 2) {
      return (networkIndicator: false, powerIndicator: false);
    }
    return (
      powerIndicator: data[0] == 1,
      networkIndicator: data[1] == 1,
    );
  }

  static List<int> loadNotification({
    required bool loadStart,
    required bool loadStop,
  }) =>
      [
        loadStart ? 1 : 0,
        loadStop ? 1 : 0,
      ];

  static ({bool loadStart, bool loadStop}) parseLoadNotification(List<int> data) {
    if (data.length < 2) {
      return (loadStart: false, loadStop: false);
    }
    return (loadStart: data[0] == 1, loadStop: data[1] == 1);
  }

  static List<int> overLoadProtection(int onOff, int thresholdW, int timeS) => [
        onOff & 0xFF,
        ...Lw005ParamHelpers.uint16Bytes(thresholdW),
        timeS & 0xFF,
      ];

  static ({bool enabled, int thresholdW, int timeS}) parseOverLoadProtection(
    List<int> data,
  ) {
    if (data.length < 4) {
      return (enabled: false, thresholdW: 0, timeS: 1);
    }
    return (
      enabled: data[0] == 1,
      thresholdW: Lw005ParamHelpers.uint16(data, offset: 1),
      timeS: data[3],
    );
  }

  static List<int> overVoltageProtection(int onOff, int thresholdV, int timeS) =>
      [
        onOff & 0xFF,
        ...Lw005ParamHelpers.uint16Bytes(thresholdV),
        timeS & 0xFF,
      ];

  static ({bool enabled, int thresholdV, int timeS}) parseOverVoltageProtection(
    List<int> data,
  ) {
    final parsed = parseOverLoadProtection(data);
    return (
      enabled: parsed.enabled,
      thresholdV: parsed.thresholdW,
      timeS: parsed.timeS,
    );
  }

  static List<int> sagVoltageProtection(int onOff, int thresholdV, int timeS) => [
        onOff & 0xFF,
        thresholdV & 0xFF,
        timeS & 0xFF,
      ];

  static ({bool enabled, int thresholdV, int timeS}) parseSagVoltageProtection(
    List<int> data,
  ) {
    if (data.length < 3) {
      return (enabled: false, thresholdV: 0, timeS: 1);
    }
    return (
      enabled: data[0] == 1,
      thresholdV: data[1],
      timeS: data[2],
    );
  }

  static List<int> overCurrentProtection(int onOff, int threshold, int timeS) =>
      sagVoltageProtection(onOff, threshold, timeS);

  static ({bool enabled, int threshold, int timeS}) parseOverCurrentProtection(
    List<int> data,
  ) {
    final parsed = parseSagVoltageProtection(data);
    return (
      enabled: parsed.enabled,
      threshold: parsed.thresholdV,
      timeS: parsed.timeS,
    );
  }

  static List<int> powerIndicatorColor({
    required int option,
    required int blue,
    required int green,
    required int yellow,
    required int orange,
    required int red,
    required int purple,
  }) =>
      [
        option & 0xFF,
        ...Lw005ParamHelpers.uint16Bytes(blue),
        ...Lw005ParamHelpers.uint16Bytes(green),
        ...Lw005ParamHelpers.uint16Bytes(yellow),
        ...Lw005ParamHelpers.uint16Bytes(orange),
        ...Lw005ParamHelpers.uint16Bytes(red),
        ...Lw005ParamHelpers.uint16Bytes(purple),
      ];

  static ({
    int option,
    int blue,
    int green,
    int yellow,
    int orange,
    int red,
    int purple,
  }) parsePowerIndicatorColor(List<int> data) {
    if (data.isEmpty) {
      return (
        option: 0,
        blue: 100,
        green: 300,
        yellow: 500,
        orange: 1000,
        red: 1800,
        purple: 2500,
      );
    }
    return (
      option: data[0],
      blue: Lw005ParamHelpers.uint16(data, offset: 1, defaultValue: 100),
      green: Lw005ParamHelpers.uint16(data, offset: 3, defaultValue: 300),
      yellow: Lw005ParamHelpers.uint16(data, offset: 5, defaultValue: 500),
      orange: Lw005ParamHelpers.uint16(data, offset: 7, defaultValue: 1000),
      red: Lw005ParamHelpers.uint16(data, offset: 9, defaultValue: 1800),
      purple: Lw005ParamHelpers.uint16(data, offset: 11, defaultValue: 2500),
    );
  }

  static String formatTotalEnergyKwh(List<int> data) {
    if (data.length < 8) {
      return '';
    }
    final total = Lw005ParamHelpers.int32(data.sublist(0, 4));
    final constant = Lw005ParamHelpers.uint16(data, offset: 6);
    if (constant == 0) {
      return '';
    }
    return (total / constant).toStringAsFixed(1);
  }
}
