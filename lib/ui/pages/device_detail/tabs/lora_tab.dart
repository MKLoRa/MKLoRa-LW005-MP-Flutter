import 'package:flutter/material.dart';

import '../../../../../ble/lw005.dart';
import '../../../../../ui/theme/device_detail_theme.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../lora/lora_app_setting_page.dart';
import '../lora/lora_conn_setting_page.dart';

class LoRaTab extends StatefulWidget {
  const LoRaTab({super.key, required this.session});

  final Lw005DeviceSession session;

  @override
  State<LoRaTab> createState() => LoRaTabState();
}

class LoRaTabState extends State<LoRaTab> {
  String _status = '-';
  String _summary = '-';

  Future<void> load({bool showOverlay = true}) async {
    if (!widget.session.client.isConnected) {
      return;
    }
    await runWithBleLoading(
      context,
      () async {
        final api = widget.session.protocol;
        final region = await api.readLoraRegion();
        final mode = await api.readLoraMode();
        final loraClass = await api.readLoraClass();
        final status = await api.readLoraNetworkStatus();
        if (!mounted) return;
        setState(() {
          _status = Lw005ParamHelpers.uint8(status.data) == 1 ? 'Connected' : 'Connecting';
          final regionIndex =
              Lw005OptionLists.regionDeviceToPicker(Lw005ParamHelpers.uint8(region.data));
          final modeIndex = Lw005ParamHelpers.uint8(mode.data) - 1;
          final regionLabel = regionIndex >= 0 && regionIndex < Lw005OptionLists.loraRegions.length
              ? Lw005OptionLists.loraRegions[regionIndex]
              : 'EU868';
          final modeLabel = modeIndex >= 0 && modeIndex < Lw005OptionLists.loraUploadMode.length
              ? Lw005OptionLists.loraUploadMode[modeIndex]
              : 'OTAA';
          final classLabel = Lw005LoraConnHelpers.loraClassSummaryLabel(
            Lw005ParamHelpers.uint8(loraClass.data),
          );
          _summary = '$modeLabel/$regionLabel/$classLabel';
        });
      },
      showOverlay: showOverlay,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SettingsCard(
          margin: EdgeInsets.zero,
          child: SettingsLabelRow(
            label: 'LoRaWAN Status',
            child: Text(
              _status,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DeviceDetailTheme.textPrimary,
              ),
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Connection Setting',
            trailing: _summary,
            onTap: () async {
              final rebooted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LoRaConnSettingPage(session: widget.session),
                ),
              );
              if (!mounted || rebooted == true || !widget.session.client.isConnected) {
                return;
              }
              await load();
            },
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Application Setting',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LoRaAppSettingPage(session: widget.session),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
