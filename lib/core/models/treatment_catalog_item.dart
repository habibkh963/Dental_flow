class TreatmentCatalogItem {
  const TreatmentCatalogItem({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };

  factory TreatmentCatalogItem.fromJson(Map<String, dynamic> json) {
    return TreatmentCatalogItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  TreatmentCatalogItem copyWith({String? id, String? name, double? price}) {
    return TreatmentCatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}
