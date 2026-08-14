import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPairTokenScreen extends StatefulWidget {
  const ScanPairTokenScreen({super.key});

  @override
  State<ScanPairTokenScreen> createState() => _ScanPairTokenScreenState();
}

class _ScanPairTokenScreenState extends State<ScanPairTokenScreen> {
  bool _hasResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasResult) {
            return;
          }
          String? rawValue;
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null &&
                barcode.rawValue!.trim().isNotEmpty) {
              rawValue = barcode.rawValue;
              break;
            }
          }
          if (rawValue == null || rawValue.trim().isEmpty) {
            return;
          }
          _hasResult = true;
          Navigator.of(context).pop(_extractToken(rawValue));
        },
      ),
    );
  }

  String _extractToken(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('token')) {
      return uri.queryParameters['token']!.trim();
    }
    return trimmed;
  }
}
