class DeviceInvite {
  const DeviceInvite({
    required this.token,
    required this.link,
    required this.shopName,
    required this.expiresAt,
  });

  final String token;
  final String link;
  final String shopName;
  final DateTime expiresAt;

  factory DeviceInvite.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return DeviceInvite(
      token: json['token'] as String,
      link: json['link'] as String,
      shopName: data['shopName'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }
}
