import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nordic_dfu/nordic_dfu.dart';

class Lw005DfuException implements Exception {
  Lw005DfuException(this.message);

  final String message;

  @override
  String toString() => message;
}

class Lw005DfuService {
  Lw005DfuService._();

  static Future<void> start({
    required String address,
    required String filePath,
    required int deviceType,
    void Function(String status)? onStatus,
    void Function(int percent)? onProgress,
  }) async {
    final completer = Completer<void>();
    var connectAttempts = 0;
    var finished = false;

    void finishError(Object error) {
      if (finished) return;
      finished = true;
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    void finishSuccess() {
      if (finished) return;
      finished = true;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    onStatus?.call('Waiting...');
    debugPrint(
      '[LW005 DFU] start address=$address file=$filePath deviceType=$deviceType',
    );

    final androidParameters = Platform.isAndroid
        ? AndroidParameters(
            keepBond: false,
            disableNotification: true,
            startAsForegroundService: false,
            disableMtuRequest: deviceType == 0 ? true : null,
            currentMtu: deviceType == 1 ? 247 : null,
          )
        : const AndroidParameters();

    NordicDfu()
        .startDfu(
          address,
          filePath,
          darwinParameters: Platform.isIOS
              ? const DarwinParameters(
                  forceScanningForNewAddressInLegacyDfu: true,
                  alternativeAdvertisingNameEnabled: true,
                )
              : const DarwinParameters(),
          androidParameters: androidParameters,
          dfuEventHandler: DfuEventHandler(
            onDeviceConnecting: (_) {
              connectAttempts++;
              onStatus?.call('Connecting...');
              if (connectAttempts > 3) {
                onStatus?.call('Error:DFU Failed');
                NordicDfu().abortDfu();
                finishError(Lw005DfuException('Error:DFU Failed'));
              }
            },
            onDfuProcessStarting: (_) => onStatus?.call('DfuProcessStarting...'),
            onEnablingDfuMode: (_) => onStatus?.call('EnablingDfuMode...'),
            onFirmwareValidating: (_) => onStatus?.call('FirmwareValidating...'),
            onProgressChanged: (_, percent, __, ___, ____, _____) {
              onProgress?.call(percent);
              onStatus?.call('Progress:$percent%');
            },
            onDfuAborted: (_) {
              onStatus?.call('DfuAborted...');
              finishError(Lw005DfuException('DfuAborted'));
            },
            onError: (_, __, ___, message) {
              debugPrint('[LW005 DFU] error: $message');
              finishError(
                Lw005DfuException(
                  message.isEmpty ? 'Opps!DFU Failed. Please try again!' : message,
                ),
              );
            },
            onDfuCompleted: (_) => finishSuccess(),
          ),
        )
        .then((_) => finishSuccess())
        .catchError((Object error) {
      debugPrint('[LW005 DFU] startDfu failed: $error');
      if (error is Lw005DfuException) {
        finishError(error);
      } else if (error is PlatformException) {
        finishError(Lw005DfuException(error.message ?? 'Opps!DFU Failed. Please try again!'));
      } else {
        finishError(Lw005DfuException('Opps!DFU Failed. Please try again!'));
      }
    });

    return completer.future;
  }
}
