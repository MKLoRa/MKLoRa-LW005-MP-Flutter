import 'package:flutter/material.dart';

import '../../models/ble_device_info.dart';
import '../../viewmodels/ble_scan_view_model.dart';

/// Scan list row aligned with native `lw005_list_item_device.xml` + `DeviceListAdapter`.
class DeviceItem extends StatelessWidget {
  final BleDeviceInfo device;
  final VoidCallback onConnect;

  const DeviceItem({super.key, required this.device, required this.onConnect});

  static const _labelStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF666666),
  );

  static const _smallLabelStyle = TextStyle(
    fontSize: 10,
    color: Color(0xFF666666),
  );

  static const _nameStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF333333),
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    final name = device.name.isNotEmpty ? device.name : 'N/A';
    final mac = device.macAddress.isNotEmpty ? device.macAddress : 'N/A';
    final txPower = device.txPowerLevel == null
        ? 'Tx Power:N/A'
        : 'Tx Power:${device.txPowerLevel}dBm';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(name, mac),
              const SizedBox(height: 13),
              _buildTxPowerRow(txPower),
              const SizedBox(height: 13),
              _buildDataGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String mac) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, right: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  color: BleScanViewModel.titleBarColor,
                  size: 22,
                ),
                const SizedBox(height: 5),
                Text('${device.rssi}dBm', style: _smallLabelStyle),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: _nameStyle),
                const SizedBox(height: 5),
                Text('MAC:$mac', style: _labelStyle),
              ],
            ),
          ),
          if (device.connectable)
            SizedBox(
              height: 35,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BleScanViewModel.titleBarColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                  minimumSize: Size.zero,
                ),
                onPressed: onConnect,
                child: const Text(
                  'CONNECT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTxPowerRow(String txPower) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(txPower, style: _labelStyle),
          ),
          Text(device.scanIntervalLabel, style: _smallLabelStyle),
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _metricLabel(
                  iconAsset: 'assets/images/lw005_ic_voltage.png',
                  text: device.voltageLabel,
                ),
              ),
              Expanded(
                child: _metricLabel(
                  iconAsset: 'assets/images/lw005_ic_current.png',
                  text: device.currentLabel,
                ),
              ),
              Expanded(
                child: _metricLabel(
                  iconAsset: 'assets/images/lw005_ic_power.png',
                  text: device.powerLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _metricLabel(
                  iconAsset: 'assets/images/lw005_ic_power_factor.png',
                  text: device.powerFactorLabel,
                ),
              ),
              Expanded(
                child: _metricLabel(
                  iconAsset: 'assets/images/lw005_ic_current_rate.png',
                  text: device.currentRateLabel,
                ),
              ),
              Expanded(
                child: _metricLabel(
                  iconAsset: device.loadStatusIconAsset,
                  text: device.loadStatusLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricLabel({required String iconAsset, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconAsset, width: 16, height: 16, fit: BoxFit.contain),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: _labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
