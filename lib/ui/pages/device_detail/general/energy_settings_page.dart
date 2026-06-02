import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_general_param_codec.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/theme/device_detail_theme.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'general_widgets.dart';

class EnergySettingsPage extends StatefulWidget {
  const EnergySettingsPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<EnergySettingsPage> createState() => _EnergySettingsPageState();
}

class _EnergySettingsPageState extends State<EnergySettingsPage> {
  final _reportController = TextEditingController();
  final _saveController = TextEditingController();
  final _powerChangeController = TextEditingController();
  String _totalEnergy = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readEnergyConfigInterval(),
        api.readPowerChangeValue(),
        api.readTotalEnergy(),
      ]);
      if (!mounted) return;
      final energy = Lw005GeneralParamCodec.parseEnergyConfigInterval(results[0].data);
      _reportController.text = energy.reportInterval.toString();
      _saveController.text = energy.saveInterval.toString();
      _powerChangeController.text = Lw005ParamHelpers.uint8(results[1].data).toString();
      _totalEnergy = Lw005GeneralParamCodec.formatTotalEnergyKwh(results[2].data);
      setState(() {});
    });
  }

  bool _validate() {
    final report = int.tryParse(_reportController.text.trim());
    final save = int.tryParse(_saveController.text.trim());
    final powerChange = int.tryParse(_powerChangeController.text.trim());
    if (report == null || save == null || powerChange == null) return false;
    if (report < 1 || report > 60 || save < 1 || save > 60) return false;
    if (report < save) return false;
    if (powerChange < 1 || powerChange > 100) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      showGeneralSaveFailed(context);
      return;
    }
    final report = int.parse(_reportController.text.trim());
    final save = int.parse(_saveController.text.trim());
    final powerChange = int.parse(_powerChangeController.text.trim());
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.writeEnergyConfigInterval(
          Lw005GeneralParamCodec.energyConfigInterval(report, save),
        ),
        api.writePowerChangeValue([powerChange]),
      ]);
      final ok = results.every((value) => value);
      if (!mounted) return;
      showProtocolResultToast(context, ok: ok);
    });
  }

  @override
  void dispose() {
    _reportController.dispose();
    _saveController.dispose();
    _powerChangeController.dispose();
    super.dispose();
  }

  Widget _minField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLength = 3,
  }) {
    return SettingsLabelRow(
      label: label,
      child: SettingsTextField(
        controller: controller,
        hint: hint,
        maxLength: maxLength,
        suffix: 'Min',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Energy Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _minField(
                  label: 'Report Interval',
                  controller: _reportController,
                  hint: '1~60',
                ),
                const SettingsFootnote('*The report interval of energy payloads'),
                const SettingsDivider(),
                _minField(
                  label: 'Energy Save Interval',
                  controller: _saveController,
                  hint: '1~60',
                ),
              ],
            ),
          ),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsLabelRow(
                  label: 'Power Change Value',
                  child: SettingsTextField(
                    controller: _powerChangeController,
                    hint: '1~100',
                    maxLength: 3,
                    suffix: '%',
                  ),
                ),
                const SettingsFootnote(
                  '*When the percentage change in power exceeds power change value, device will immediately store the energy data.',
                ),
              ],
            ),
          ),
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsLabelRow(
              label: 'Total Energy',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _totalEnergy,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DeviceDetailTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'KWH',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DeviceDetailTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
