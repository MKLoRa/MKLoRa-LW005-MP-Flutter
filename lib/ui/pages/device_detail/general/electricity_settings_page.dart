import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'general_widgets.dart';

class ElectricitySettingsPage extends StatefulWidget {
  const ElectricitySettingsPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<ElectricitySettingsPage> createState() => _ElectricitySettingsPageState();
}

class _ElectricitySettingsPageState extends State<ElectricitySettingsPage> {
  final _intervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readElectricityReportInterval();
      if (!mounted) return;
      _intervalController.text =
          Lw005ParamHelpers.bytesToInt(result.data).toString();
      setState(() {});
    });
  }

  bool _validate() {
    final value = int.tryParse(_intervalController.text.trim());
    if (value == null) return false;
    return value >= 5 && value <= 600;
  }

  Future<void> _save() async {
    if (!_validate()) {
      showGeneralSaveFailed(context);
      return;
    }
    final interval = int.parse(_intervalController.text.trim());
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writeElectricityReportInterval(
        Lw005ParamHelpers.uint16Bytes(interval),
      );
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
      title: 'Electricity Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            margin: EdgeInsets.zero,
            child: ReportIntervalField(
              controller: _intervalController,
              hint: '5~600',
              maxLength: 5,
              footnote: '*The report interval of electricity payloads',
            ),
          ),
        ],
      ),
    );
  }
}
