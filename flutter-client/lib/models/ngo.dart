class Ngo {
  final String id;
  final String name;
  final String country;
  final String category;
  final bool isVerified;

  Ngo({
    required this.id,
    required this.name,
    required this.country,
    required this.category,
    required this.isVerified,
  });

  factory Ngo.fromJson(Map<String, dynamic> j) => Ngo(
        id: (j["_id"] ?? j["id"]).toString(),
        name: (j["name"] ?? "").toString(),
        country: (j["country"] ?? "").toString(),
        category: (j["category"] ?? "").toString(),
        isVerified: (j["isVerified"] ?? false) == true,
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "country": country,
        "category": category,
        "isVerified": isVerified,
      };
}
