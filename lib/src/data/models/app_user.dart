class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.shopId,
    this.shopName,
  });

  final String id;
  final String name;
  final String role;
  final String? shopId;
  final String? shopName;

  bool get isOwner => role == 'owner';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      shopId: json['shopId'] as String?,
      shopName: json['shopName'] as String?,
    );
  }
}
