import 'dart:convert';
import 'dart:typed_data';

import 'lw005_constants.dart';

class Lw005ProtocolCodec {
  Lw005ProtocolCodec._();

  static List<int> buildReadFrame({
    required int key,
    bool packet = false,
  }) {
    if (packet) {
      return [
        Lw005ProtocolConstants.headPacket,
        Lw005ProtocolConstants.flagRead,
        key,
        0x00,
      ];
    }
    return [
      Lw005ProtocolConstants.headSingle,
      Lw005ProtocolConstants.flagRead,
      key,
      0x00,
    ];
  }

  static List<int> buildWriteFrame({
    required int key,
    required List<int> data,
    bool packet = false,
    int packetCount = 1,
    int packetIndex = 0,
  }) {
    if (packet) {
      return [
        Lw005ProtocolConstants.headPacket,
        Lw005ProtocolConstants.flagWrite,
        key,
        packetCount,
        packetIndex,
        data.length,
        ...data,
      ];
    }
    return [
      Lw005ProtocolConstants.headSingle,
      Lw005ProtocolConstants.flagWrite,
      key,
      data.length,
      ...data,
    ];
  }

  static List<int> buildPasswordFrame(String password) {
    final passwordBytes = utf8.encode(password);
    return [
      Lw005ProtocolConstants.headSingle,
      Lw005ProtocolConstants.flagWrite,
      Lw005ProtocolConstants.passwordCmd,
      passwordBytes.length,
      ...passwordBytes,
    ];
  }

  static bool isPasswordSuccess(List<int> value) {
    if (value.length < 5) {
      return false;
    }
    return value[0] == Lw005ProtocolConstants.headSingle &&
        value[1] == Lw005ProtocolConstants.flagWrite &&
        value[2] == Lw005ProtocolConstants.passwordCmd &&
        value[3] == 0x01 &&
        value[4] == 0x01;
  }

  static bool isWriteAck(List<int> value, int key) {
    if (value.length < 5) {
      return false;
    }
    return value[0] == Lw005ProtocolConstants.headSingle &&
        value[1] == Lw005ProtocolConstants.flagWrite &&
        (value[2] & 0xFF) == key &&
        value[3] == 0x01;
  }

  static bool isWriteSuccess(List<int> value, int key) {
    return isWriteAck(value, key) && value[4] == 0x01;
  }

  static Lw005ParsedFrame? parseReadResponse(List<int> value) {
    if (value.isEmpty) {
      return null;
    }
    final header = value[0];
    if (header == Lw005ProtocolConstants.headSingle) {
      if (value.length < 4) {
        return null;
      }
      final key = value[2] & 0xFF;
      final length = value[3];
      if (value.length < 4 + length) {
        return null;
      }
      return Lw005ParsedFrame(
        key: key,
        data: value.sublist(4, 4 + length),
      );
    }
    if (header == Lw005ProtocolConstants.headPacket) {
      if (value.length < 6) {
        return null;
      }
      final key = value[2] & 0xFF;
      final length = value[5];
      if (value.length < 6 + length) {
        return null;
      }
      return Lw005ParsedFrame(
        key: key,
        data: value.sublist(6, 6 + length),
        packetIndex: value[4],
        packetCount: value[3],
      );
    }
    return null;
  }

  static List<int> reassemblePacketResponses(List<List<int>> packets) {
    if (packets.isEmpty) {
      return const [];
    }
    final first = packets.first;
    if (first.isEmpty || first[0] != Lw005ProtocolConstants.headPacket) {
      return const [];
    }
    final buffer = BytesBuilder();
    for (final packet in packets) {
      if (packet.length < 6) {
        continue;
      }
      final length = packet[5];
      buffer.add(packet.sublist(6, 6 + length));
    }
    final data = buffer.toBytes();
    final key = first[2] & 0xFF;
    return [
      Lw005ProtocolConstants.headSingle,
      Lw005ProtocolConstants.flagRead,
      key,
      data.length,
      ...data,
    ];
  }
}

class Lw005ParsedFrame {
  const Lw005ParsedFrame({
    required this.key,
    required this.data,
    this.packetIndex,
    this.packetCount,
  });

  final int key;
  final List<int> data;
  final int? packetIndex;
  final int? packetCount;
}
