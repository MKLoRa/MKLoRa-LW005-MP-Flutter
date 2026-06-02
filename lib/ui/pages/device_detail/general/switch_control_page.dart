import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_param_key.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';

class SwitchControlPage extends StatefulWidget {
  const SwitchControlPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<SwitchControlPage> createState() => _SwitchControlPageState();
}

class _SwitchControlPageState extends State<SwitchControlPage> {
  static const _defaultModes = ['Off', 'On', 'Restore Last Mode'];
  final _intervalController = TextEditingController();
  int _defaultModeIndex = 0;
  bool _switchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readSwitchStatus(),
        api.readSwitchPayloadReportInterval(),
        api.readPowerOnDefaultMode(),
      ]);
      if (!mounted) return;
      _switchOn = Lw005ParamHelpers.uint8(results[0].data) == 1;
      _intervalController.text = Lw005ParamHelpers.uint16(results[1].data).toString();
      final mode = Lw005ParamHelpers.uint8(results[2].data);
      _defaultModeIndex = mode.clamp(0, 2);
      setState(() {});
    });
  }

  Future<void> _pickDefaultMode() async {
    final index = await showBottomPicker(
      context: context,
      options: _defaultModes,
      selectedIndex: _defaultModeIndex,
    );
    if (index == null) return;
    setState(() => _defaultModeIndex = index);
  }

  Future<void> _save() async {
    final interval = int.tryParse(_intervalController.text.trim());
    if (interval == null || interval < 10 || interval > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interval must be 10~600')),
      );
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = await Future.wait([
        api.writeSwitchPayloadReportInterval(Lw005ParamHelpers.uint16Bytes(interval)),
        api.writePowerOnDefaultMode([_defaultModeIndex]),
      ]).then((r) => r.every((v) => v));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Save Successfully！' : 'Save failed')),
      );
    });
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Switch Control')),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Switch Status',
              child: Text(
                _switchOn ? 'ON' : 'OFF',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Switch Payload Report Interval',
              child: SettingsTextField(
                controller: _intervalController,
                hint: '10~600',
                maxLength: 4,
                suffix: 'S',
              ),
            ),
          ),
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Power-on Default Mode',
              child: BlueValueButton(
                text: _defaultModes[_defaultModeIndex],
                onTap: _pickDefaultMode,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('SAVE')),
        ],
      ),
    );
  }
}
