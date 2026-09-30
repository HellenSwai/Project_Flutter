import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final supabase = Supabase.instance.client;

  int totalProducts = 0;
  int lowStock = 0;
  double stockValue = 0;
  double totalCostValue = 0;
  double potentialProfit = 0;

  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final products = await supabase
          .from('products')
          .select(
            'name, buying_price, selling_price, quantity, created_at',
          );

      int productCount = products.length;
      int lowStockCount = 0;
      double sellingValue = 0;
      double costValue = 0;

      for (final product in products) {
        final quantity = (product['quantity'] as num?)?.toInt() ?? 0;
        final buyingPrice =
            (product['buying_price'] as num?)?.toDouble() ?? 0;
        final sellingPrice =
            (product['selling_price'] as num?)?.toDouble() ?? 0;

        if (quantity <= 10) {
          lowStockCount++;
        }

        sellingValue += sellingPrice * quantity;
        costValue += buyingPrice * quantity;
      }

      if (!mounted) return;

      setState(() {
        totalProducts = productCount;
        lowStock = lowStockCount;
        stockValue = sellingValue;
        totalCostValue = costValue;
        potentialProfit = sellingValue - costValue;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  String formatMoney(double amount) {
    return "TZS ${amount.toStringAsFixed(0)}";
  }

  Widget reportRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadReport,
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "Unable to load report",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          onPressed: loadReport,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Try Again"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadReport,

                  child: ListView(
                    padding: const EdgeInsets.all(16),

                    children: [
                      // HEADER
                      const Text(
                        "Business Report",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Current inventory summary",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ONE MAIN REPORT CARD
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(20),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              // CARD TITLE
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.bar_chart,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Inventory Report",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      SizedBox(height: 3),

                                      Text(
                                        "Live data from Supabase",
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              const Divider(),

                              // TOTAL PRODUCTS
                              reportRow(
                                icon: Icons.inventory_2,
                                title: "Total Products",
                                value: "$totalProducts",
                              ),

                              const Divider(),

                              // STOCK VALUE
                              reportRow(
                                icon: Icons.payments,
                                title: "Stock Selling Value",
                                value: formatMoney(stockValue),
                              ),

                              const Divider(),

                              // COST VALUE
                              reportRow(
                                icon: Icons.shopping_cart,
                                title: "Stock Buying Value",
                                value: formatMoney(totalCostValue),
                              ),

                              const Divider(),

                              // POTENTIAL PROFIT
                              reportRow(
                                icon: Icons.trending_up,
                                title: "Potential Profit",
                                value: formatMoney(potentialProfit),
                                valueColor: Colors.green,
                              ),

                              const Divider(),

                              // LOW STOCK
                              reportRow(
                                icon: Icons.warning_amber,
                                title: "Low Stock Products",
                                value: "$lowStock",
                                valueColor: lowStock > 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // INFORMATION CARD
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(18),

                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.deepPurple,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  "This report is calculated from the "
                                  "current products stored in Supabase. "
                                  "Pull down to refresh the information.",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    
                
                  )],
                  ),
                ),
    );
  }
}