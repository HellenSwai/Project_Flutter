class SaleItem {
  final String id;              // uuid
  final String saleId;          // uuid → sales.id
  final String productId;       // uuid → products.id
  final String productName;
  final double quantity;
  final double buyingPrice;
  final double sellingPrice;
  final double total;
  final double profit;
  final DateTime? createdAt;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.total,
    required this.profit,
    this.createdAt,
  });

  // FROM Supabase JSON → SaleItem
  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String,
      saleId: json['sale_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      buyingPrice: (json['buying_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // SaleItem → JSON (for insert into Supabase)
  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'total': total,
      'profit': profit,
    };
  }

  // Convenience: build from a Product + quantity
  factory SaleItem.fromProduct({
    required String saleId,
    required String productId,
    required String productName,
    required double quantity,
    required double buyingPrice,
    required double sellingPrice,
  }) {
    final total = sellingPrice * quantity;
    final profit = (sellingPrice - buyingPrice) * quantity;

    return SaleItem(
      id: '', // assigned by DB
      saleId: saleId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      buyingPrice: buyingPrice,
      sellingPrice: sellingPrice,
      total: total,
      profit: profit,
    );
  }

  @override
  String toString() =>
      'SaleItem($productName × $quantity = $total)';
}