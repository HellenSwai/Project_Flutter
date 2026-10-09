class Product {
  final String id;              // uuid
  final String name;
  final double buyingPrice;
  final double sellingPrice;
  final double quantity;
  final String? category;
  final String? description;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    this.category,
    this.description,
    this.createdAt,
  });


  // Convert FROM Supabase JSON → Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      buyingPrice: (json['buying_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }


  // Convert Product → JSON (for insert/update on Supabase)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'category': category,
      'description': description,
    };
  }


  // Helper: profit per unit
  double get profitPerUnit => sellingPrice - buyingPrice;


  // Helper: is stock low?
  bool get isLowStock => quantity > 0 && quantity <= 5;
  bool get isOutOfStock => quantity <= 0;


  // copyWith (useful for state updates)
  Product copyWith({
    String? id,
    String? name,
    double? buyingPrice,
    double? sellingPrice,
    double? quantity,
    String? category,
    String? description,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Product($name, stock: $quantity)';
}