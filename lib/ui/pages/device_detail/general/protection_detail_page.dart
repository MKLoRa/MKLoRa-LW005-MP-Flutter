import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_general_param_codec.dart';
import '../../../../ble/lw005_param_key.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'general_widgets.dart';

enum Lw005ProtectionType {
  overLoad,
  overVoltage,
  sagVoltage,
  overCurrent,
}

class ProtectionDetailPage extends StatefulWidget {
  const ProtectionDetailPage({
    super.key,
    required this.session,
    required this.type,
    required this.deviceSpecification,
  });

  final Lw005DeviceSession session;
  final Lw005ProtectionType type;
  final int deviceSpecification;

  @override
  State<ProtectionDetailPage> createState() => _ProtectionDetailPageState();
}

class _ProtectionDetailPageState extends State<ProtectionDetailPage> {
  bool _enabled = false;
  final _thresholdController = TextEditingController();
  final _timeController = TextEditingController();

  String get _title => switch (widget.type) {
        Lw005ProtectionType.overLoad => 'Over-Load Protection',
        Lw005ProtectionType.overVoltage => 'Over-Voltage Protection',
        Lw005ProtectionType.sagVoltage => 'Sag-Voltage Protection',
        Lw005ProtectionType.overCurrent => 'Over-Current Protection',
      };

  String get _switchLabel => switch (widget.type) {
        Lw005ProtectionType.overLoad => 'Over-Load Protection',
        Lw005ProtectionType.overVoltage => 'Over-Voltage Protection',
        Lw005ProtectionType.sagVoltage => 'Sag-Voltage Protection',
        Lw005ProtectionType.overCurrent => 'Over-Current Protection',
      };

  String get _thresholdLabel => switch (widget.type) {
        Lw005ProtectionType.overLoad => 'Over-Load Threshold',
        Lw005ProtectionType.overVoltage => 'Over-Voltage Threshold',
        Lw005ProtectionType.sagVoltage => 'Sag-Voltage Threshold',
        Lw005ProtectionType.overCurrent => 'Over-Current Threshold',
      };

  String? get _thresholdSuffix => switch (widget.type) {
        Lw005ProtectionType.overLoad => 'W',
        Lw005ProtectionType.overVoltage => 'V',
        Lw005ProtectionType.sagVoltage => 'V',
        Lw005ProtectionType.overCurrent => 'x0.1 A',
      };

  Lw005ParamKey get _paramKey => switch (widget.type) {
        Lw005ProtectionType.overLoad => Lw005ParamKey.overLoadProtection,
        Lw005ProtectionType.overVoltage => Lw005ParamKey.overVoltageProtection,
        Lw005ProtectionType.sagVoltage => Lw005ParamKey.sagVoltageProtection,
        Lw005ProtectionType.overCurrent => Lw005ParamKey.overCurrentProtection,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readParam(_paramKey);
      if (!mounted) return;
      _applyRead(result.data);
      setState(() {});
    });
  }

  void _applyRead(List<int> data) {
    switch (widget.type) {
      case Lw005ProtectionType.overLoad:
        final parsed = Lw005GeneralParamCodec.parseOverLoadProtection(data);
        _enabled = parsed.enabled;
        _thresholdController.text = parsed.thresholdW.toString();
        _timeController.text = parsed.timeS.toString();
      case Lw005ProtectionType.overVoltage:
        final parsed = Lw005GeneralParamCodec.parseOverVoltageProtection(data);
        _enabled = parsed.enabled;
        _thresholdController.text = parsed.thresholdV.toString();
        _timeController.text = parsed.timeS.toString();
      case Lw005ProtectionType.sagVoltage:
        final parsed = Lw005GeneralParamCodec.parseSagVoltageProtection(data);
        _enabled = parsed.enabled;
        _thresholdController.text = parsed.thresholdV.toString();
        _timeController.text = parsed.timeS.toString();
      case Lw005ProtectionType.overCurrent:
        final parsed = Lw005GeneralParamCodec.parseOverCurrentProtection(data);
        _enabled = parsed.enabled;
        _thresholdController.text = parsed.threshold.toString();
        _timeController.text = parsed.timeS.toString();
    }
  }

  List<int> _encodeWrite() {
    final threshold = int.parse(_thresholdController.text.trim());
    final time = int.parse(_timeController.text.trim());
    final onOff = _enabled ? 1 : 0;
    return switch (widget.type) {
      Lw005ProtectionType.overLoad =>
        Lw005GeneralParamCodec.overLoadProtection(onOff, threshold, time),
      Lw005ProtectionType.overVoltage =>
        Lw005GeneralParamCodec.overVoltageProtection(onOff, threshold, time),
      Lw005ProtectionType.sagVoltage =>
        Lw005GeneralParamCodec.sagVoltageProtection(onOff, threshold, time),
      Lw005ProtectionType.overCurrent =>
        Lw005GeneralParamCodec.overCurrentProtection(onOff, threshold, time),
    };
  }

  bool _validate() {
    final threshold = int.tryParse(_thresholdController.text.trim());
    final time = int.tryParse(_timeController.text.trim());
    if (threshold == null || time == null) return false;
    if (time < 1 || time > 30) return false;

    switch (widget.type) {
      case Lw005ProtectionType.overLoad:
        final max = lw005MaxPowerW(widget.deviceSpecification);
        return threshold >= 10 && threshold <= max;
      case Lw005ProtectionType.overVoltage:
        final spec = widget.deviceSpecification;
        final min = spec == 1 ? 121 : 231;
        final max = spec == 1 ? 138 : 264;
        return threshold >= min && threshold <= max;
      case Lw005ProtectionType.sagVoltage:
        final spec = widget.deviceSpecification;
        final min = spec == 1 ? 102 : 196;
        final max = spec == 1 ? 119 : 229;
        return threshold >= min && threshold <= max;
      case Lw005ProtectionType.overCurrent:
        final spec = widget.deviceSpecification;
        final max = spec == 1 ? 180 : (spec == 2 ? 156 : 192);
        return threshold >= 1 && threshold <= max;
    }
  }

  Future<void> _save() async {
    if (!_validate()) {
      showGeneralSaveFailed(context);
      return;
    }
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writeParam(
        _paramKey,
        _encodeWrite(),
      );
      if (!mounted) return;
      showProtocolResultToast(context, ok: ok);
    });
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: _title,
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsSwitchRow(
              label: _switchLabel,
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
          ),
          SettingsCard(
            child: SettingsLabelRow(
              label: _thresholdLabel,
              child: SettingsTextField(
                controller: _thresholdController,
                maxLength: widget.type == Lw005ProtectionType.overCurrent ? 3 : 4,
                suffix: _thresholdSuffix,
              ),
            ),
          ),
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsLabelRow(
              label: 'Time Threshold',
              child: SettingsTextField(
                controller: _timeController,
                hint: '1~30',
                maxLength: 2,
                suffix: 'S',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
