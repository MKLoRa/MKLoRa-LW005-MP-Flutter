import 'package:flutter/material.dart';

import '../../../../ble/lw005_device_session.dart';
import '../../../../ble/lw005_general_param_codec.dart';
import '../../../../ble/lw005_param_helpers.dart';
import '../../../../ble/lw005_protocol_named_api.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'general_widgets.dart';

class LoadStatusNotificationPage extends StatefulWidget {
  const LoadStatusNotificationPage({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<LoadStatusNotificationPage> createState() =>
      _LoadStatusNotificationPageState();
}

class _LoadStatusNotificationPageState extends State<LoadStatusNotificationPage> {
  final _thresholdController = TextEditingController();
  bool _loadStartNotification = false;
  bool _loadStopNotification = false;
  bool _loadOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readLoadStatus(),
        api.readLoadNotification(),
        api.readLoadStatusThreshold(),
      ]);
      if (!mounted) return;
      _loadOn = Lw005ParamHelpers.uint8(results[0].data) == 1;
      final notification =
          Lw005GeneralParamCodec.parseLoadNotification(results[1].data);
      _loadStartNotification = notification.loadStart;
      _loadStopNotification = notification.loadStop;
      _thresholdController.text =
          Lw005ParamHelpers.uint8(results[2].data).toString();
      setState(() {});
    });
  }

  bool _validate() {
    final value = int.tryParse(_thresholdController.text.trim());
    if (value == null) return false;
    return value >= 1 && value <= 10;
  }

  Future<void> _save() async {
    if (!_validate()) {
      showGeneralSaveFailed(context);
      return;
    }
    final threshold = int.parse(_thresholdController.text.trim());
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.writeLoadNotification(
          Lw005GeneralParamCodec.loadNotification(
            loadStart: _loadStartNotification,
            loadStop: _loadStopNotification,
          ),
        ),
        api.writeLoadStatusThreshold([threshold]),
      ]);
      final ok = results.every((value) => value);
      if (!mounted) return;
      showProtocolResultToast(context, ok: ok);
    });
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Load Status Notification',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsLabelRow(
              label: 'Load Status',
              child: Image.asset(
                _loadOn
                    ? 'assets/images/lw005_ic_load_open.png'
                    : 'assets/images/lw005_ic_load_close.png',
                width: 28,
                height: 28,
              ),
            ),
          ),
          SettingsCard(
            child: Column(
              children: [
                SettingsSwitchRow(
                  label: 'Load Start Notification',
                  value: _loadStartNotification,
                  onChanged: (value) =>
                      setState(() => _loadStartNotification = value),
                ),
                const SettingsDivider(),
                SettingsSwitchRow(
                  label: 'Load Stop Notification',
                  value: _loadStopNotification,
                  onChanged: (value) =>
                      setState(() => _loadStopNotification = value),
                ),
              ],
            ),
          ),
          SettingsCard(
            margin: EdgeInsets.zero,
            child: SettingsLabelRow(
              label: 'Load Status Threshold',
              child: SettingsTextField(
                controller: _thresholdController,
                hint: '1~10',
                maxLength: 2,
                suffix: 'x0.1 W',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
