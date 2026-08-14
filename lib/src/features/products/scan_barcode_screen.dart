import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  bool _hasResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasResult) {
            return;
          }
          String? code;
          for (final barcode in capture.barcodes) {
            final rawValue = barcode.rawValue;
            if (rawValue != null && rawValue.trim().isNotEmpty) {
              code = rawValue.trim();
              break;
            }
          }
          if (code == null) {
            return;
          }
          _hasResult = true;
          Navigator.of(context).pop(code);
        },
      ),
    );
  }
}
