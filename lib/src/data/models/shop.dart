class Shop {
  const Shop({required this.id, required this.name, this.location = ''});

  final String id;
  final String name;
  final String location;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      location: (json['location'] as String?) ?? '',
    );
  }
}
