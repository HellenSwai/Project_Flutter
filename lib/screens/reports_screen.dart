import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  int totalProducts = 0;
  int lowStock = 0;

  double stockSellingValue = 0;
  double stockBuyingValue = 0;
  double potentialProfit = 0;

  // Controls which report is opened
  String? expandedReport;

  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    try {
      setState(() {
        loading = true;
      });

      final data = await supabase
          .from('products')
          .select(
            'id, name, buying_price, selling_price, quantity',
          );

      final List<Map<String, dynamic>> productList =
          List<Map<String, dynamic>>.from(data);

      double sellingValue = 0;
      double buyingValue = 0;

      for (final product in productList) {
        final double buying =
            (product['buying_price'] as num?)?.toDouble() ?? 0;

        final double selling =
            (product['selling_price'] as num?)?.toDouble() ?? 0;

        final int quantity =
            (product['quantity'] as num?)?.toInt() ?? 0;

        buyingValue += buying * quantity;
        sellingValue += selling * quantity;
      }

      if (!mounted) return;

      setState(() {
        products = productList;
        totalProducts = productList.length;
        lowStock = productList.where((p) {
          final quantity = (p['quantity'] as num?)?.toInt() ?? 0;
          return quantity <= 10;
        }).length;

        stockSellingValue = sellingValue;
        stockBuyingValue = buyingValue;
        potentialProfit = sellingValue - buyingValue;

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading report: $e'),
        ),
      );
    }
  }

  void toggleReport(String report) {
    setState(() {
      if (expandedReport == report) {
        expandedReport = null;
      } else {
        expandedReport = report;
      }
    });
  }

  String money(double amount) {
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  Widget reportRow({
    required String title,
    required String value,
    required IconData icon,
    required String reportKey,
  }) {
    final bool isExpanded = expandedReport == reportKey;

    return Column(
      children: [
        InkWell(
          onTap: () => toggleReport(reportKey),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 10,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.deepPurple,
                  size: 27,
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        if (isExpanded) buildDetails(reportKey),

        const Divider(height: 1),
      ],
    );
  }

  Widget buildDetails(String reportKey) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No products available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    List<Map<String, dynamic>> displayedProducts = products;

    // Low stock only
    if (reportKey == 'lowStock') {
      displayedProducts = products.where((product) {
        final quantity =
            (product['quantity'] as num?)?.toInt() ?? 0;

        return quantity <= 10;
      }).toList();

      if (displayedProducts.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No low stock products.',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (final product in displayedProducts)
            buildProductDetail(
              product,
              reportKey,
            ),
        ],
      ),
    );
  }

  Widget buildProductDetail(
    Map<String, dynamic> product,
    String reportKey,
  ) {
    final String name = product['name']?.toString() ?? 'Unknown';

    final double buying =
        (product['buying_price'] as num?)?.toDouble() ?? 0;

    final double selling =
        (product['selling_price'] as num?)?.toDouble() ?? 0;

    final int quantity =
        (product['quantity'] as num?)?.toInt() ?? 0;

    final double sellingValue = selling * quantity;
    final double buyingValue = buying * quantity;
    final double profit = sellingValue - buyingValue;

    String detailText = '';

    if (reportKey == 'totalProducts') {
      detailText =
          'Quantity: $quantity\n'
          'Selling Price: ${money(selling)}';
    } else if (reportKey == 'sellingValue') {
      detailText =
          'Quantity: $quantity\n'
          'Selling Price: ${money(selling)}\n'
          'Stock Selling Value: ${money(sellingValue)}';
    } else if (reportKey == 'buyingValue') {
      detailText =
          'Quantity: $quantity\n'
          'Buying Price: ${money(buying)}\n'
          'Stock Buying Value: ${money(buyingValue)}';
    } else if (reportKey == 'profit') {
      detailText =
          'Quantity: $quantity\n'
          'Buying Value: ${money(buyingValue)}\n'
          'Selling Value: ${money(sellingValue)}\n'
          'Potential Profit: ${money(profit)}';
    } else if (reportKey == 'lowStock') {
      detailText =
          'Available Stock: $quantity\n'
          'Selling Price: ${money(selling)}';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: Colors.deepPurple,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  detailText,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
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
        title: const Text('Reports'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Report',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Tap any report to view details',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // TOTAL PRODUCTS
                          reportRow(
                            title: 'Total Products',
                            value: totalProducts.toString(),
                            icon: Icons.inventory_2,
                            reportKey: 'totalProducts',
                          ),

                          // STOCK SELLING VALUE
                          reportRow(
                            title: 'Stock Selling Value',
                            value: money(stockSellingValue),
                            icon: Icons.sell,
                            reportKey: 'sellingValue',
                          ),

                          // STOCK BUYING VALUE
                          reportRow(
                            title: 'Stock Buying Value',
                            value: money(stockBuyingValue),
                            icon: Icons.shopping_cart,
                            reportKey: 'buyingValue',
                          ),

                          // POTENTIAL PROFIT
                          reportRow(
                            title: 'Potential Profit',
                            value: money(potentialProfit),
                            icon: Icons.trending_up,
                            reportKey: 'profit',
                          ),

                          // LOW STOCK
                          reportRow(
                            title: 'Low Stock Products',
                            value: lowStock.toString(),
                            icon: Icons.warning_amber,
                            reportKey: 'lowStock',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}