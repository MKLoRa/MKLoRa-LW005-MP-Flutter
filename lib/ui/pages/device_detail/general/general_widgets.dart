import 'package:flutter/material.dart';

import '../../../../ui/theme/device_detail_theme.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';

const kGeneralSaveFailedMessage =
    'Opps！Save failed. Please check the input characters and try again.';

void showGeneralSaveFailed(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(kGeneralSaveFailedMessage)),
  );
}

class SettingsFootnote extends StatelessWidget {
  const SettingsFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: DeviceDetailTheme.textPrimary,
        ),
      ),
    );
  }
}

class ReportIntervalField extends StatelessWidget {
  const ReportIntervalField({
    super.key,
    required this.controller,
    required this.hint,
    this.suffix = 's',
    this.maxLength = 5,
    this.footnote,
  });

  final TextEditingController controller;
  final String hint;
  final String suffix;
  final int maxLength;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsLabelRow(
          label: 'Report Interval',
          child: SettingsTextField(
            controller: controller,
            hint: hint,
            maxLength: maxLength,
            suffix: suffix.isEmpty ? null : suffix,
          ),
        ),
        if (footnote != null) SettingsFootnote(footnote!),
      ],
    );
  }
}

/// Max rated power (W) by device specification byte from native apps.
int lw005MaxPowerW(int deviceSpecification) {
  switch (deviceSpecification) {
    case 1:
      return 2160;
    case 2:
      return 3588;
    default:
      return 4416;
  }
}
