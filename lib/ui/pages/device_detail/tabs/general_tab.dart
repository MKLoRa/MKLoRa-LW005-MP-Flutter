import 'package:flutter/material.dart';

import '../../../../../ble/lw005_device_session.dart';
import '../../../../../ble/lw005_param_key.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../general/lw005_uint16_param_page.dart';
import '../general/switch_control_page.dart';

class GeneralTab extends StatefulWidget {
  const GeneralTab({super.key, required this.session, required this.onSaveReady});

  final Lw005DeviceSession session;
  final void Function(Future<bool> Function() save) onSaveReady;

  @override
  State<GeneralTab> createState() => GeneralTabState();
}

class GeneralTabState extends State<GeneralTab> {
  @override
  void initState() {
    super.initState();
    widget.onSaveReady(() async => true);
  }

  Future<void> load({bool showOverlay = true}) async {}

  void _openUint16Page({
    required String title,
    required Lw005ParamKey key,
    required String hint,
    required int min,
    required int max,
    String suffix = 'S',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Lw005Uint16ParamPage(
          session: widget.session,
          title: title,
          paramKey: key,
          hint: hint,
          min: min,
          max: max,
          suffix: suffix,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SettingsCard(
          child: SettingsNavRow(
            title: 'Switch Control',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SwitchControlPage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Electricity Settings',
            onTap: () => _openUint16Page(
              title: 'Electricity Settings',
              key: Lw005ParamKey.electricityReportInterval,
              hint: '5~600',
              min: 5,
              max: 600,
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Energy Settings',
            onTap: () => _openUint16Page(
              title: 'Energy Settings',
              key: Lw005ParamKey.energyConfigInterval,
              hint: '1~65535',
              min: 1,
              max: 65535,
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Protection Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Open protection sub-settings from native app reference.'),
                ),
              );
            },
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Load Status Notification',
            onTap: () => _openUint16Page(
              title: 'Load Status Notification',
              key: Lw005ParamKey.loadNotification,
              hint: '0~255',
              min: 0,
              max: 255,
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Countdown Settings',
            onTap: () => _openUint16Page(
              title: 'Countdown Settings',
              key: Lw005ParamKey.countdownReportInterval,
              hint: '1~65535',
              min: 1,
              max: 65535,
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'LED Settings',
            onTap: () => _openUint16Page(
              title: 'LED Settings',
              key: Lw005ParamKey.ledIndicatorStatus,
              hint: '0~1',
              min: 0,
              max: 1,
              suffix: '',
            ),
          ),
        ),
      ],
    );
  }
}
