import 'dart:convert';

import 'package:intl/intl.dart';

import '../models/receipt.dart';

class EscPosReceiptBuilder {
  EscPosReceiptBuilder({this.paperWidth = 48});

  final int paperWidth;

  List<int> build(Receipt receipt) {
    final bytes = <int>[
      0x1b,
      0x40,
    ];
    _center(bytes);
    _bold(bytes, true);
    _writeln(
        bytes, _fit(receipt.shopName.isEmpty ? 'Smart POS' : receipt.shopName));
    _bold(bytes, false);
    _left(bytes);
    _line(bytes);
    _writeln(bytes, 'Receipt: ${receipt.receiptNumber}');
    _writeln(bytes, 'Cashier: ${receipt.cashierName}');
    _writeln(
      bytes,
      'Date: ${DateFormat('dd MMM yyyy HH:mm').format(receipt.createdAt.toLocal())}',
    );
    _line(bytes);
    for (final item in receipt.items) {
      _writeln(bytes, _fit(item.name));
      _writeln(
        bytes,
        _columns(
          '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)}',
          item.lineTotal.toStringAsFixed(2),
        ),
      );
    }
    _line(bytes);
    _bold(bytes, true);
    _writeln(bytes, _columns('TOTAL', receipt.total.toStringAsFixed(2)));
    _bold(bytes, false);
    _writeln(bytes, 'Paid by: ${receipt.paymentMethod}');
    _line(bytes);
    _center(bytes);
    _writeln(bytes, 'Thank you');
    _feed(bytes, 4);
    bytes.addAll([0x1d, 0x56, 0x41, 0x10]);
    return bytes;
  }

  String _columns(String left, String right) {
    final cleanLeft = _fit(left);
    final cleanRight = _fit(right);
    final space = paperWidth - cleanLeft.length - cleanRight.length;
    if (space <= 1) {
      final leftWidth = paperWidth - cleanRight.length - 1;
      return '${cleanLeft.substring(0, leftWidth.clamp(0, cleanLeft.length))} $cleanRight';
    }
    return '$cleanLeft${''.padLeft(space)}$cleanRight';
  }

  String _fit(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= paperWidth) {
      return normalized;
    }
    return normalized.substring(0, paperWidth);
  }

  void _line(List<int> bytes) => _writeln(bytes, ''.padLeft(paperWidth, '-'));

  void _writeln(List<int> bytes, String value) {
    bytes.addAll(latin1.encode(value));
    bytes.add(0x0a);
  }

  void _bold(List<int> bytes, bool enabled) {
    bytes.addAll([0x1b, 0x45, enabled ? 1 : 0]);
  }

  void _center(List<int> bytes) {
    bytes.addAll([0x1b, 0x61, 1]);
  }

  void _left(List<int> bytes) {
    bytes.addAll([0x1b, 0x61, 0]);
  }

  void _feed(List<int> bytes, int lines) {
    for (var i = 0; i < lines; i += 1) {
      bytes.add(0x0a);
    }
  }
}
