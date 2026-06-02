import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_general_param_codec.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/theme/device_detail_theme.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'general_widgets.dart';

class PowerIndicatorColorPage extends StatefulWidget {
  const PowerIndicatorColorPage({
    super.key,
    required this.session,
    required this.deviceSpecification,
  });

  final Lw005DeviceSession session;
  final int deviceSpecification;

  @override
  State<PowerIndicatorColorPage> createState() => _PowerIndicatorColorPageState();
}

class _PowerIndicatorColorPageState extends State<PowerIndicatorColorPage> {
  static const _colorTypeOptions = [
    'Active power indicator with color direct transition',
    'Active power indicator with color smooth transition',
    'White',
    'Red',
    'Green',
    'Blue',
    'Orange',
    'Cyan',
    'Purple',
  ];

  int _selectedType = 0;
  final _blueController = TextEditingController(text: '100');
  final _greenController = TextEditingController(text: '300');
  final _yellowController = TextEditingController(text: '500');
  final _orangeController = TextEditingController(text: '1000');
  final _redController = TextEditingController(text: '1800');
  final _purpleController = TextEditingController(text: '2500');

  bool get _showColorThresholds => _selectedType <= 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readPowerIndicatorColor();
      if (!mounted) return;
      final parsed = Lw005GeneralParamCodec.parsePowerIndicatorColor(result.data);
      _selectedType = parsed.option.clamp(0, _colorTypeOptions.length - 1);
      _blueController.text = parsed.blue.toString();
      _greenController.text = parsed.green.toString();
      _yellowController.text = parsed.yellow.toString();
      _orangeController.text = parsed.orange.toString();
      _redController.text = parsed.red.toString();
      _purpleController.text = parsed.purple.toString();
      setState(() {});
    });
  }

  Future<void> _pickColorType() async {
    final index = await showBottomPicker(
      context: context,
      options: _colorTypeOptions,
      selectedIndex: _selectedType,
    );
    if (index == null) return;
    setState(() => _selectedType = index);
  }

  bool _validate() {
    if (!_showColorThresholds) return true;
    final blue = int.tryParse(_blueController.text.trim());
    final green = int.tryParse(_greenController.text.trim());
    final yellow = int.tryParse(_yellowController.text.trim());
    final orange = int.tryParse(_orangeController.text.trim());
    final red = int.tryParse(_redController.text.trim());
    final purple = int.tryParse(_purpleController.text.trim());
    if ([blue, green, yellow, orange, red, purple].any((v) => v == null)) {
      return false;
    }
    final max = lw005MaxPowerW(widget.deviceSpecification);
    if (blue! < 2 || blue >= max - 5) return false;
    if (green! <= blue || green > max - 4) return false;
    if (yellow! <= green || yellow > max - 3) return false;
    if (orange! <= yellow || orange > max - 2) return false;
    if (red! <= orange || red > max - 1) return false;
    if (purple! <= red || purple > max) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      showGeneralSaveFailed(context);
      return;
    }
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writePowerIndicatorColor(
        Lw005GeneralParamCodec.powerIndicatorColor(
          option: _selectedType,
          blue: int.parse(_blueController.text.trim()),
          green: int.parse(_greenController.text.trim()),
          yellow: int.parse(_yellowController.text.trim()),
          orange: int.parse(_orangeController.text.trim()),
          red: int.parse(_redController.text.trim()),
          purple: int.parse(_purpleController.text.trim()),
        ),
      );
      if (!mounted) return;
      showProtocolResultToast(context, ok: ok);
    });
  }

  @override
  void dispose() {
    _blueController.dispose();
    _greenController.dispose();
    _yellowController.dispose();
    _orangeController.dispose();
    _redController.dispose();
    _purpleController.dispose();
    super.dispose();
  }

  Widget _colorField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeviceDetailTheme.textPrimary,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Power Indicator Color',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select power indicator with color when device is on',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DeviceDetailTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                BlueValueButton(
                  text: _colorTypeOptions[_selectedType],
                  onTap: _pickColorType,
                ),
              ],
            ),
          ),
          if (_showColorThresholds)
            SettingsCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _colorField('Measured power for blue LED(W)', _blueController),
                  _colorField('Measured power for green LED(W)', _greenController),
                  _colorField('Measured power for yellow LED(W) ', _yellowController),
                  _colorField('Measured power for orange LED(W) ', _orangeController),
                  _colorField('Measured power for red LED(W) ', _redController),
                  _colorField('Measured power for purple LED(W) ', _purpleController),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
