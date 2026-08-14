import 'app_user.dart';
import 'product.dart';
import 'shift.dart';
import 'shop.dart';

class BootstrapData {
  const BootstrapData({
    required this.user,
    required this.shop,
    required this.products,
    this.currentShift,
  });

  final AppUser user;
  final Shop shop;
  final List<Product> products;
  final Shift? currentShift;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      shop: Shop.fromJson(json['shop'] as Map<String, dynamic>),
      currentShift: json['currentShift'] == null
          ? null
          : Shift.fromJson(json['currentShift'] as Map<String, dynamic>),
      products: (json['products'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
