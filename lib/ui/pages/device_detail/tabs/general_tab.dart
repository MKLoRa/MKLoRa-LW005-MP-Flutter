import 'package:flutter/material.dart';

import '../../../../../ble/lw005_device_session.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../general/countdown_settings_page.dart';
import '../general/electricity_settings_page.dart';
import '../general/energy_settings_page.dart';
import '../general/led_settings_page.dart';
import '../general/load_status_notification_page.dart';
import '../general/protection_settings_page.dart';
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

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SettingsCard(
          child: SettingsNavRow(
            title: 'Switch Control',
            onTap: () => _open(SwitchControlPage(session: widget.session)),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Electricity Settings',
            onTap: () => _open(ElectricitySettingsPage(session: widget.session)),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Energy Settings',
            onTap: () => _open(EnergySettingsPage(session: widget.session)),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Protection Settings',
            onTap: () => _open(ProtectionSettingsPage(session: widget.session)),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Load Status Notification',
            onTap: () => _open(LoadStatusNotificationPage(session: widget.session)),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Countdown Settings',
            onTap: () => _open(CountdownSettingsPage(session: widget.session)),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'LED Settings',
            onTap: () => _open(LedSettingsPage(session: widget.session)),
          ),
        ),
      ],
    );
  }
}
