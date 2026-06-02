import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/theme/device_detail_theme.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class SwitchControlPage extends StatefulWidget {
  const SwitchControlPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<SwitchControlPage> createState() => _SwitchControlPageState();
}

class _SwitchControlPageState extends State<SwitchControlPage> {
  static const _powerOnModes = ['Off', 'On', 'Restore Last Mode'];

  final _intervalController = TextEditingController();
  bool _switchOn = false;
  int _powerOnModeIndex = 0;

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
      _powerOnModeIndex = Lw005ParamHelpers.uint8(results[2].data).clamp(0, 2);
      setState(() {});
    });
  }

  Future<void> _pickPowerOnDefaultMode() async {
    final index = await showBottomPicker(
      context: context,
      options: _powerOnModes,
      selectedIndex: _powerOnModeIndex,
    );
    if (index == null) return;
    setState(() => _powerOnModeIndex = index);
  }

  bool _validateInterval() {
    final text = _intervalController.text.trim();
    if (text.isEmpty) return false;
    final interval = int.tryParse(text);
    if (interval == null) return false;
    return interval >= 10 && interval <= 600;
  }

  Future<void> _save() async {
    if (!_validateInterval()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opps！Save failed. Please check the input characters and try again.',
            ),
          ),
        );
      }
      return;
    }
    final interval = int.parse(_intervalController.text.trim());
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.writeSwitchStatus([_switchOn ? 1 : 0]),
        api.writeSwitchPayloadReportInterval(Lw005ParamHelpers.uint16Bytes(interval)),
        api.writePowerOnDefaultMode([_powerOnModeIndex]),
      ]);
      final ok = results.every((value) => value);
      if (!mounted) return;
      showProtocolResultToast(context, ok: ok);
    });
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Switch Control',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsSwitchRow(
              label: 'ON/OFF',
              value: _switchOn,
              onChanged: (value) => setState(() => _switchOn = value),
            ),
          ),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsLabelRow(
                  label: 'Report Interval',
                  child: SettingsTextField(
                    controller: _intervalController,
                    hint: '10~600',
                    maxLength: 5,
                    suffix: 's',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '*The report interval of switch payloads',
                    style: TextStyle(
                      fontSize: 12,
                      color: DeviceDetailTheme.textPrimary,
                    ),
                  ),
                ),
                const SettingsDivider(),
                SettingsLabelRow(
                  label: 'Power On Default Mode',
                  child: BlueValueButton(
                    text: _powerOnModes[_powerOnModeIndex],
                    onTap: _pickPowerOnDefaultMode,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
