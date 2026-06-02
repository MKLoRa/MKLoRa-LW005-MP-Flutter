import 'lw005_param_helpers.dart';

class Lw005PayloadConfig {
  const Lw005PayloadConfig({required this.confirmed, required this.retransIndex});

  final bool confirmed;
  final int retransIndex;

  static Lw005PayloadConfig fromBytes(List<int> data) {
    if (data.length < 2) {
      return const Lw005PayloadConfig(confirmed: false, retransIndex: 0);
    }
    return Lw005PayloadConfig(
      confirmed: data[0] == 1,
      retransIndex: (data[1] - 1).clamp(0, 3),
    );
  }

  List<int> toBytes() => [confirmed ? 1 : 0, retransIndex + 1];
}

class Lw005TimePoint {
  Lw005TimePoint({required this.hour, required this.minute});

  int hour;
  int minute;

  int toMinutes() => hour * 60 + minute;

  static Lw005TimePoint fromMinutes(int value) {
    if (value == 0) {
      return Lw005TimePoint(hour: 0, minute: 0);
    }
    final hour = value ~/ 60;
    final minute = value % 60;
    return Lw005TimePoint(hour: hour == 24 ? 0 : hour, minute: minute);
  }
}

class Lw005TimeSegment {
  Lw005TimeSegment({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.reportInterval,
  });

  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  int reportInterval;

  List<int> encode() {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return [
      ...Lw005ParamHelpers.uint16Bytes(start),
      ...Lw005ParamHelpers.uint16Bytes(end),
      ...Lw005ParamHelpers.int32Bytes(reportInterval),
    ];
  }
}

class Lw005ExportRecord {
  Lw005ExportRecord({required this.rawData, DateTime? time}) : time = time ?? DateTime.now();

  final DateTime time;
  final String rawData;
}

class Lw005StorageNotifyParseResult {
  const Lw005StorageNotifyParseResult({this.records, this.totalSum});

  final List<Lw005ExportRecord>? records;
  final int? totalSum;
}

class Lw005DataCodec {
  Lw005DataCodec._();

  /// Timing mode report points: one byte per point, 15-minute slots (native setTimePosReportPoints).
  static List<int> encodeTimePoints(List<Lw005TimePoint> points) {
    final bytes = <int>[];
    for (final point in points) {
      if (point.hour == 0 && point.minute == 0) {
        bytes.add(96);
      } else {
        bytes.add((point.hour * 60 + point.minute) ~/ 15);
      }
    }
    return bytes;
  }

  static List<Lw005TimePoint> decodeTimePoints(List<int> data) {
    final points = <Lw005TimePoint>[];
    for (final slot in data) {
      final totalMinutes = (slot & 0xFF) * 15;
      var hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      if (hour == 24) {
        hour = 0;
      }
      points.add(Lw005TimePoint(hour: hour, minute: minute));
    }
    return points;
  }

  static List<int> encodeTimeSegments(List<Lw005TimeSegment> segments) {
    final bytes = <int>[];
    for (final segment in segments) {
      bytes.addAll(segment.encode());
    }
    return bytes;
  }

  static List<Lw005TimeSegment> decodeTimeSegments(List<int> data) {
    final segments = <Lw005TimeSegment>[];
    for (var i = 0; i + 7 < data.length; i += 8) {
      final start = Lw005ParamHelpers.uint16(data.sublist(i, i + 2));
      final end = Lw005ParamHelpers.uint16(data.sublist(i + 2, i + 4));
      final interval = Lw005ParamHelpers.int32(data.sublist(i + 4, i + 8));
      final startPoint = Lw005TimePoint.fromMinutes(start);
      final endPoint = Lw005TimePoint.fromMinutes(end);
      segments.add(
        Lw005TimeSegment(
          startHour: startPoint.hour,
          startMinute: startPoint.minute,
          endHour: endPoint.hour,
          endMinute: endPoint.minute,
          reportInterval: interval,
        ),
      );
    }
    return segments;
  }

  static List<String> decodeMacRules(List<int> data) {
    final rules = <String>[];
    var index = 0;
    while (index < data.length) {
      final length = data[index];
      index++;
      if (index + length > data.length) break;
      rules.add(Lw005ParamHelpers.bytesToHex(data.sublist(index, index + length)));
      index += length;
    }
    return rules;
  }

  static List<int> encodeMacRules(List<String> macs) {
    final bytes = <int>[];
    for (final mac in macs) {
      final macBytes = Lw005ParamHelpers.hexToBytes(mac);
      if (macBytes.isEmpty) continue;
      bytes.add(macBytes.length);
      bytes.addAll(macBytes);
    }
    return bytes;
  }

  static List<String> decodeNameRules(List<int> data) {
    final rules = <String>[];
    var index = 0;
    while (index < data.length) {
      final length = data[index];
      index++;
      if (index + length > data.length) break;
      rules.add(String.fromCharCodes(data.sublist(index, index + length)));
      index += length;
    }
    return rules;
  }

  static List<int> encodeNameRules(List<String> names) {
    final bytes = <int>[];
    for (final name in names) {
      final nameBytes = name.codeUnits;
      if (nameBytes.isEmpty) continue;
      bytes.add(nameBytes.length);
      bytes.addAll(nameBytes);
    }
    return bytes;
  }

  /// LW005 indicator bitmask (1 byte), aligned with native IndicatorSettingsActivity.
  static int encodeIndicator({
    required bool lowPower,
    required bool networkCheck,
    required bool fix,
    required bool fixSuccess,
    required bool fixFail,
  }) =>
      (lowPower ? 1 : 0) |
      (networkCheck ? 2 : 0) |
      (fix ? 4 : 0) |
      (fixSuccess ? 8 : 0) |
      (fixFail ? 16 : 0);

  static Map<String, bool> decodeIndicator(int value) {
    return {
      'lowPower': (value & 1) == 1,
      'networkCheck': (value & 2) == 2,
      'fix': (value & 4) == 4,
      'fixSuccess': (value & 8) == 8,
      'fixFail': (value & 16) == 16,
    };
  }

  static Map<String, bool> decodeSelftestStatus(int value) {
    return {
      'ok': value == 0,
      'gpsFail': (value & 0x01) == 0x01,
      'axisFail': (value & 0x02) == 0x02,
      'flashFail': (value & 0x04) == 0x04,
    };
  }

  /// SelfTestNewActivity reads status from response byte index 5 (payload index 1).
  static int decodeSelftestStatusValue(List<int> data) {
    if (data.length >= 2) {
      return data[1];
    }
    if (data.isNotEmpty) {
      return data[0];
    }
    return 0;
  }

  /// LW005 SelfTestActivity battery block: 6 x 4-byte big-endian fields.
  static Map<String, dynamic>? decodeSelfTestBatteryInfo(List<int> data) {
    if (data.length < 24) {
      return null;
    }
    int readField(int offset) =>
        Lw005ParamHelpers.bytesToInt(data.sublist(offset, offset + 4));
    final consumeRaw = readField(20);
    return {
      'runtime': readField(0),
      'advTimes': readField(4),
      'thSampleRate': readField(8),
      'loraPower': readField(12),
      'loraTransmissionTimes': readField(16),
      'batteryConsumeMah': consumeRaw * 0.001,
    };
  }

  static Map<String, int>? decodeBatteryInfo(List<int> data) {
    if (data.length < 36) {
      return null;
    }
    int readField(int offset) =>
        Lw005ParamHelpers.bytesToInt(data.sublist(offset, offset + 4));
    return {
      'runtime': readField(0),
      'advTimes': readField(4),
      'flashTimes': readField(8),
      'axisDuration': readField(12),
      'bleFixDuration': readField(16),
      'wifiFixDuration': readField(20),
      'gpsFixDuration': readField(24),
      'loraTransmissionTimes': readField(28),
      'loraPower': readField(32),
    };
  }

  /// LW005 battery consume block (0x08/0x09/0x0A): 12 x 4-byte big-endian fields.
  static Map<String, dynamic>? decodeBatteryConsumeInfo(List<int> data) {
    if (data.length < 48) {
      return null;
    }
    int readField(int offset) =>
        Lw005ParamHelpers.bytesToInt(data.sublist(offset, offset + 4));
    final consumeRaw = readField(44);
    return {
      'runtime': readField(0),
      'advTimes': readField(4),
      'axisDuration': readField(8),
      'bleFixDuration': readField(12),
      'wifiFixDuration': readField(16),
      'gpsL76FixDuration': readField(20),
      'gpsLrFixDuration': readField(24),
      'staticPosPayload': readField(28),
      'motionPosPayload': readField(32),
      'loraTransmissionTimes': readField(36),
      'loraPower': readField(40),
      'batteryConsumeMah': consumeRaw * 0.001,
    };
  }

  static String formatBatteryConsumeMah(double value) {
    return value.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  static Lw005StorageNotifyParseResult? parseStorageNotify(List<int> value) {
    if (value.length < 5 || value[0] != 0xED || value[1] != 0x02) {
      return null;
    }
    final cmd = value[2] & 0xFF;
    if (cmd != 0x01) {
      return null;
    }
    final dataCount = value[4] & 0xFF;
    if (dataCount > 0) {
      final notifyTime = DateTime.now();
      final records = <Lw005ExportRecord>[];
      var index = 5;
      while (index < value.length) {
        final dataLength = value[index] & 0xFF;
        index++;
        var rawData = '';
        if (dataLength > 0 && index + dataLength <= value.length) {
          rawData = Lw005ParamHelpers.bytesToHex(
            value.sublist(index, index + dataLength),
          );
          index += dataLength;
        }
        records.add(Lw005ExportRecord(rawData: rawData, time: notifyTime));
      }
      return Lw005StorageNotifyParseResult(records: records);
    }
    if (value.length > 5) {
      var sum = 0;
      for (var i = 5; i < value.length; i++) {
        sum = (sum << 8) | (value[i] & 0xFF);
      }
      return Lw005StorageNotifyParseResult(totalSum: sum);
    }
    return null;
  }

  static List<int> encodeLoraUplinkStrategy({
    required bool adr,
    required int dr1,
    required int dr2,
  }) =>
      [adr ? 1 : 0, dr1, dr2];

  static List<int> encodeAccCondition(int threshold, int duration) => [threshold, duration];
}
