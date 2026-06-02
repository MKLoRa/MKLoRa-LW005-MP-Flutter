import 'package:flutter/material.dart';

import '../../../../../ble/lw005.dart';
import '../../../../../ble/lw005_device_session.dart';
import '../../../../../ble/lw005_param_helpers.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/common_confirm_dialog.dart';
import '../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../../../../viewmodels/ble_scan_view_model.dart';
import '../device/system_info_page.dart';

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<DeviceTab> createState() => DeviceTabState();
}

class DeviceTabState extends State<DeviceTab> {
  int _timeZoneIndex = 40;

  Future<void> reload({bool showOverlay = true}) async {
    await runWithBleLoading(
      context,
      () async {
        final result = await widget.session.protocol.readTimeZone();
        if (!mounted) return;
        setState(() {
          _timeZoneIndex = Lw005ParamHelpers.timeZoneIndexFromBytes(result.data);
        });
      },
      showOverlay: showOverlay,
    );
  }

  Future<void> _pickTimeZone() async {
    final zones = Lw005OptionLists.timeZones();
    final index = await showBottomPicker(
      context: context,
      options: zones,
      selectedIndex: _timeZoneIndex,
    );
    if (index == null || !mounted) return;
    setState(() => _timeZoneIndex = index);
    await runWithBleLoading(context, () async {
      await widget.session.protocol.writeTimeZone(
        Lw005ParamHelpers.timeZoneBytesFromIndex(index),
      );
      await reload(showOverlay: false);
    });
  }

  Future<void> _factoryReset() async {
    final ok = await showCommonConfirmDialog(
      context: context,
      title: 'Factory Reset!',
      message: 'After factory reset,all the data will be reseted to the factory values.',
      confirmText: 'OK',
      showCancel: false,
      actionColor: BleScanViewModel.titleBarColor,
    );
    if (!ok || !mounted) return;
    await runWithBleLoading(context, () => widget.session.protocol.writeResetEmpty());
  }

  @override
  Widget build(BuildContext context) {
    final zones = Lw005OptionLists.timeZones();
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SettingsCard(
          child: SettingsLabelRow(
            label: 'Current Time Zone',
            child: BlueValueButton(
              text: zones[_timeZoneIndex.clamp(0, zones.length - 1)],
              onTap: _pickTimeZone,
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Device Information',
            onTap: () async {
              final result = await Navigator.of(context).push<SystemInfoDfuResult>(
                MaterialPageRoute(
                  builder: (_) => SystemInfoPage(session: widget.session),
                ),
              );
              if (!context.mounted) return;
              if (result == SystemInfoDfuResult.success ||
                  result == SystemInfoDfuResult.failed) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Factory Reset',
            onTap: _factoryReset,
          ),
        ),
      ],
    );
  }
}
