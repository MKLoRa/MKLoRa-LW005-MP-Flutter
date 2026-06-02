import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import 'protection_detail_page.dart';

class ProtectionSettingsPage extends StatefulWidget {
  const ProtectionSettingsPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<ProtectionSettingsPage> createState() => _ProtectionSettingsPageState();
}

class _ProtectionSettingsPageState extends State<ProtectionSettingsPage> {
  int _deviceSpecification = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readDeviceSpecification();
      if (!mounted) return;
      _deviceSpecification = Lw005ParamHelpers.uint8(result.data);
      setState(() {});
    });
  }

  void _open(Lw005ProtectionType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectionDetailPage(
          session: widget.session,
          type: type,
          deviceSpecification: _deviceSpecification,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Protection Settings',
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsNavRow(
              title: 'Over-Load Protection',
              onTap: () => _open(Lw005ProtectionType.overLoad),
            ),
          ),
          SettingsCard(
            child: SettingsNavRow(
              title: 'Over-Voltage Protection',
              onTap: () => _open(Lw005ProtectionType.overVoltage),
            ),
          ),
          SettingsCard(
            child: SettingsNavRow(
              title: 'Sag-Voltage Protection',
              onTap: () => _open(Lw005ProtectionType.sagVoltage),
            ),
          ),
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsNavRow(
              title: 'Over-Current Protection',
              onTap: () => _open(Lw005ProtectionType.overCurrent),
            ),
          ),
        ],
      ),
    );
  }
}
