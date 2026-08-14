class Receipt {
  const Receipt({
    required this.id,
    required this.receiptNumber,
    required this.shopName,
    required this.cashierName,
    required this.createdAt,
    required this.paymentMethod,
    required this.total,
    required this.status,
    required this.items,
  });

  final String id;
  final String receiptNumber;
  final String shopName;
  final String cashierName;
  final DateTime createdAt;
  final String paymentMethod;
  final double total;
  final String status;
  final List<ReceiptItem> items;

  factory Receipt.fromPayload({
    required String status,
    required Map<String, dynamic> payload,
    String shopName = '',
  }) {
    return Receipt(
      id: payload['id'] as String,
      receiptNumber: payload['receiptNumber'] as String,
      shopName: shopName,
      cashierName: (payload['cashierName'] as String?) ?? '',
      createdAt: DateTime.tryParse((payload['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      paymentMethod: (payload['paymentMethod'] as String?) ?? 'cash',
      total: ((payload['grandTotal'] as num?) ?? 0).toDouble(),
      status: status,
      items: ((payload['items'] as List<dynamic>?) ?? const [])
          .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.code,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final String code;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['productName'] as String,
      code: json['productCode'] as String,
      quantity: ((json['quantity'] as num?) ?? 0).toInt(),
      unitPrice: ((json['unitPrice'] as num?) ?? 0).toDouble(),
      lineTotal: ((json['lineTotal'] as num?) ?? 0).toDouble(),
    );
  }
}
