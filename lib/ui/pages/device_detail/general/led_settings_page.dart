import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_general_param_codec.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'power_indicator_color_page.dart';

class LedSettingsPage extends StatefulWidget {
  const LedSettingsPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<LedSettingsPage> createState() => _LedSettingsPageState();
}

class _LedSettingsPageState extends State<LedSettingsPage> {
  bool _networkIndicator = false;
  bool _powerIndicator = false;
  int _deviceSpecification = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readLedIndicatorStatus(),
        api.readDeviceSpecification(),
      ]);
      if (!mounted) return;
      final led = Lw005GeneralParamCodec.parseLedIndicatorStatus(results[0].data);
      _networkIndicator = led.networkIndicator;
      _powerIndicator = led.powerIndicator;
      _deviceSpecification = Lw005ParamHelpers.uint8(results[1].data);
      setState(() {});
    });
  }

  Future<void> _save() async {
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writeLedIndicatorStatus(
        Lw005GeneralParamCodec.ledIndicatorStatus(
          networkIndicator: _networkIndicator,
          powerIndicator: _powerIndicator,
        ),
      );
      if (!mounted) return;
      showProtocolResultToast(context, ok: ok);
    });
  }

  void _openPowerIndicatorColor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PowerIndicatorColorPage(
          session: widget.session,
          deviceSpecification: _deviceSpecification,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'LED Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsNavRow(
              title: 'Power Indicator Color',
              onTap: _openPowerIndicatorColor,
            ),
          ),
          SettingsCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsSwitchRow(
                  label: 'Network Indicator Status',
                  value: _networkIndicator,
                  onChanged: (value) => setState(() => _networkIndicator = value),
                ),
                const SettingsDivider(),
                SettingsSwitchRow(
                  label: 'Power Indicator Status',
                  value: _powerIndicator,
                  onChanged: (value) => setState(() => _powerIndicator = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
