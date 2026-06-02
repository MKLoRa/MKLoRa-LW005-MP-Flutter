import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../ble/lw005.dart';
import '../../../../dfu/lw005_dfu_coordinator.dart';
import '../../../../dfu/lw005_dfu_service.dart';
import '../../../../dfu/lw005_dfu_utils.dart';
import '../../../../ui/theme/device_detail_theme.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/common_confirm_dialog.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../../../ui/widgets/dfu_progress_dialog.dart';
import '../../../../viewmodels/ble_scan_view_model.dart';
import 'log_data_page.dart';

enum SystemInfoDfuResult {
  success,
  failed,
}

class SystemInfoPage extends StatefulWidget {
  const SystemInfoPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  String _software = '-';
  String _manufacturer = '-';
  String _firmware = '-';
  String _hardware = '-';
  String _model = '-';
  String _mac = '-';
  String _advName = '';
  var _dfuRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final gatt = widget.session.deviceInfoApi;
      final advName = await api.readAdvName();
      final mac = await api.readChipMac();
      final model = await gatt.readModelNumber();
      final software = await gatt.readSoftwareRevision();
      final firmware = await gatt.readFirmwareRevision();
      final hardware = await gatt.readHardwareRevision();
      final manufacturer = await gatt.readManufacturerName();
      if (!mounted) return;
      setState(() {
        _advName = Lw005ParamHelpers.bytesToString(advName.data);
        _mac = Lw005ParamHelpers.formatMac(mac.data);
        if (_mac.isEmpty) _mac = '-';
        _model = model.isEmpty ? '-' : model;
        _software = software.isEmpty ? '-' : software;
        _firmware = firmware.isEmpty ? '-' : firmware;
        _hardware = hardware.isEmpty ? '-' : hardware;
        _manufacturer = manufacturer.isEmpty ? '-' : manufacturer;
      });
    });
  }

  void _openDebuggerMode() {
    if (_mac == '-' || _mac.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogDataPage(
          session: widget.session,
          deviceMac: _mac,
        ),
      ),
    );
  }

  Future<void> _updateFirmware() async {
    if (_dfuRunning || _mac == '-' || _mac.isEmpty || _advName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Para error!')),
        );
      }
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );
    if (!mounted || picked == null) return;

    late final String firmwarePath;
    try {
      firmwarePath = await lw005PrepareDfuFirmwarePath(picked.files.single);
    } on Lw005DfuFileException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
      return;
    }

    final dfuAddress = lw005DfuDeviceAddress(
      deviceInfo: widget.session.deviceInfo,
      chipMac: _mac,
    );

    setState(() => _dfuRunning = true);
    DfuProgressHandle? progress;
    try {
      Lw005DfuCoordinator.begin(mac: _mac);
      await widget.session.disconnect();

      progress = await showDfuProgressDialog(context);
      await Lw005DfuService.start(
        address: dfuAddress,
        filePath: firmwarePath,
        deviceType: widget.session.deviceInfo.deviceType,
        onStatus: progress.update,
      );

      if (!mounted) return;
      closeDfuProgressDialog(context);
      await showCommonConfirmDialog(
        context: context,
        message: 'Update firmware successfully!\nPlease reconnect the device.',
        confirmText: 'OK',
        actionColor: BleScanViewModel.titleBarColor,
        barrierDismissible: false,
        showCancel: false,
      );
      if (mounted) {
        Navigator.of(context).pop(SystemInfoDfuResult.success);
      }
    } on Lw005DfuException catch (error) {
      if (mounted) {
        closeDfuProgressDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
        Navigator.of(context).pop(SystemInfoDfuResult.failed);
      }
    } catch (error) {
      if (mounted) {
        closeDfuProgressDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is Lw005DfuException
                  ? error.message
                  : 'Opps!DFU Failed. Please try again!',
            ),
          ),
        );
        Navigator.of(context).pop(SystemInfoDfuResult.failed);
      }
    } finally {
      Lw005DfuCoordinator.end();
      if (mounted) {
        setState(() => _dfuRunning = false);
      }
    }
  }

  Widget _infoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DeviceDetailTheme.textPrimary,
              ),
            ),
          ),
          if (trailing == null)
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          else ...[
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Device Information',
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoRow('Software Version', _software),
                const SettingsDivider(),
                _infoRow(
                  'Firmware Version',
                  _firmware,
                  trailing: SizedBox(
                    width: 70,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _dfuRunning ? null : _updateFirmware,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DeviceDetailTheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('DFU', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
                const SettingsDivider(),
                _infoRow('Hardware Version', _hardware),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoRow('MAC Address', _mac),
                const SettingsDivider(),
                _infoRow('Product Model', _model),
                const SettingsDivider(),
                _infoRow('Manufacturer', _manufacturer),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SettingsCard(
            child: SettingsNavRow(
              title: 'Debugger Mode',
              onTap: _openDebuggerMode,
            ),
          ),
        ],
      ),
    );
  }
}
