import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_param_key.dart';
import '../../../../ble/lw005_protocol_api.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';

class Lw005Uint16ParamPage extends StatefulWidget {
  const Lw005Uint16ParamPage({
    super.key,
    required this.session,
    required this.title,
    required this.paramKey,
    required this.hint,
    required this.min,
    required this.max,
    this.suffix = 'S',
  });

  final Lw005DeviceSession session;
  final String title;
  final Lw005ParamKey paramKey;
  final String hint;
  final int min;
  final int max;
  final String suffix;

  @override
  State<Lw005Uint16ParamPage> createState() => _Lw005Uint16ParamPageState();
}

class _Lw005Uint16ParamPageState extends State<Lw005Uint16ParamPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readParam(widget.paramKey);
      if (!mounted) return;
      _controller.text = Lw005ParamHelpers.uint16(result.data).toString();
      setState(() {});
    });
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < widget.min || value > widget.max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Value must be ${widget.min}~${widget.max}')),
      );
      return;
    }
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writeParam(
        widget.paramKey,
        Lw005ParamHelpers.uint16Bytes(value),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Save Successfully！' : 'Save failed')),
      );
      if (ok) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Report Interval',
              child: SettingsTextField(
                controller: _controller,
                hint: widget.hint,
                maxLength: 4,
                suffix: widget.suffix,
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
