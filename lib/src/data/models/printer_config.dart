class PrinterConfig {
  const PrinterConfig({
    required this.transport,
    this.name = '',
    this.address = '',
    this.paperWidth = 48,
  });

  final String transport;
  final String name;
  final String address;
  final int paperWidth;

  bool get isConfigured => transport != 'none' && address.isNotEmpty;

  factory PrinterConfig.none() {
    return const PrinterConfig(transport: 'none');
  }

  factory PrinterConfig.fromJson(Map<String, String> json) {
    return PrinterConfig(
      transport: json['transport'] ?? 'none',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      paperWidth: int.tryParse(json['paperWidth'] ?? '') ?? 48,
    );
  }
}

class PairedPrinter {
  const PairedPrinter({
    required this.name,
    required this.address,
  });

  final String name;
  final String address;
}
