class Sale {
  final String id;             // uuid
  final double totalAmount;
  final double totalProfit;
  final DateTime? createdAt;

  Sale({
    required this.id,
    required this.totalAmount,
    required this.totalProfit,
    this.createdAt,
  });

  // FROM Supabase JSON → Sale
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }


  // Sale → JSON (for insert)
  Map<String, dynamic> toJson() {
    return {
      'total_amount': totalAmount,
      'total_profit': totalProfit,
    };
  }

  @override
  String toString() =>
      'Sale(total: $totalAmount, profit: $totalProfit)';
}