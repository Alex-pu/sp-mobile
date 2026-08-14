class Shift {
  const Shift({
    required this.id,
    required this.shopId,
    required this.cashierId,
    required this.status,
    required this.openingFloat,
    this.closingCash,
    this.expectedCash,
    this.variance,
    this.notes = '',
  });

  final String id;
  final String shopId;
  final String cashierId;
  final String status;
  final double openingFloat;
  final double? closingCash;
  final double? expectedCash;
  final double? variance;
  final String notes;

  bool get isOpen => status == 'open';

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      cashierId: json['cashierId'] as String,
      status: json['status'] as String,
      openingFloat: ((json['openingFloat'] as num?) ?? 0).toDouble(),
      closingCash: (json['closingCash'] as num?)?.toDouble(),
      expectedCash: (json['expectedCash'] as num?)?.toDouble(),
      variance: (json['variance'] as num?)?.toDouble(),
      notes: (json['notes'] as String?) ?? '',
    );
  }
}
