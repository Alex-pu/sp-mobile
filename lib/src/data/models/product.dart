class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.sellingPrice,
    required this.stockLevel,
    required this.reorderLevel,
    this.category = 'General',
    this.costPrice = 0,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int stockLevel;
  final int reorderLevel;
  final bool isActive;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      category: (json['category'] as String?) ?? 'General',
      costPrice: ((json['costPrice'] as num?) ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      stockLevel: ((json['stockLevel'] as num?) ?? 0).toInt(),
      reorderLevel: ((json['reorderLevel'] as num?) ?? 10).toInt(),
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  factory Product.fromDb(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as String,
      code: row['code'] as String,
      name: row['name'] as String,
      category: (row['category'] as String?) ?? 'General',
      costPrice: ((row['cost_price'] as num?) ?? 0).toDouble(),
      sellingPrice: (row['selling_price'] as num).toDouble(),
      stockLevel: ((row['stock_level'] as num?) ?? 0).toInt(),
      reorderLevel: ((row['reorder_level'] as num?) ?? 10).toInt(),
      isActive: ((row['is_active'] as num?) ?? 1).toInt() == 1,
    );
  }

  Map<String, Object?> toDb() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'stock_level': stockLevel,
      'reorder_level': reorderLevel,
      'is_active': isActive ? 1 : 0,
    };
  }

  Product copyWith({int? stockLevel}) {
    return Product(
      id: id,
      code: code,
      name: name,
      category: category,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stockLevel: stockLevel ?? this.stockLevel,
      reorderLevel: reorderLevel,
      isActive: isActive,
    );
  }
}
