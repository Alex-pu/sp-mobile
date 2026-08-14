class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.shopId,
    this.shopName,
  });

  final String id;
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final String? shopId;
  final String? shopName;

  bool get isOwner => role == 'owner';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      shopId: json['shopId'] as String?,
      shopName: json['shopName'] as String?,
    );
  }
}
