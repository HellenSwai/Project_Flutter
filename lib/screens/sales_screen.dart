import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final supabase = Supabase.instance.client;

  // ============================================================
  // STATE
  // ============================================================
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> todaySales = [];

  Map<String, dynamic>? selectedProduct;

  final quantityController = TextEditingController();

  bool loadingProducts = true;
  bool savingSale = false;

  // Float quantity (supports 1.5 kg, 0.25 L, etc.)
  double quantity = 1.0;

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void initState() {
    super.initState();
    loadProducts();
    loadTodaySales();
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================
  Future<void> loadProducts() async {
    try {
      final data = await supabase.from('products').select().order('name');
      if (!mounted) return;
      setState(() {
        products = List<Map<String, dynamic>>.from(data);
        loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingProducts = false);
      showMessage("Failed to load products: $e", Colors.red);
    }
  }

  // ============================================================
  // LOAD TODAY'S SALES
  // ============================================================
  Future<void> loadTodaySales() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final data = await supabase
          .from('sale_items')
          .select()
          .gte('created_at', startOfDay.toIso8601String())
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        todaySales = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;
      showMessage("Failed to load sales: $e", Colors.red);
    }
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================
  double get sellingPrice => selectedProduct == null
      ? 0
      : (selectedProduct!['selling_price'] as num).toDouble();

  double get buyingPrice => selectedProduct == null
      ? 0
      : (selectedProduct!['buying_price'] as num).toDouble();

  double get availableStock => selectedProduct == null
      ? 0
      : (selectedProduct!['quantity'] as num).toDouble();

  double get totalAmount => sellingPrice * quantity;

  double get totalProfit => (sellingPrice - buyingPrice) * quantity;

  // ============================================================
  // TODAY'S TOTALS
  // ============================================================
  double get todayTotalSales => todaySales.fold(
        0.0,
        (sum, s) => sum + ((s['total'] as num?)?.toDouble() ?? 0),
      );

  double get todayTotalProfit => todaySales.fold(
        0.0,
        (sum, s) => sum + ((s['profit'] as num?)?.toDouble() ?? 0),
      );

  double get todayTotalItems => todaySales.fold(
        0.0,
        (sum, s) => sum + ((s['quantity'] as num?)?.toDouble() ?? 0),
      );

  // ============================================================
  // RECORD SALE
  // ============================================================
  Future<void> recordSale() async {
    // Validate product
    if (selectedProduct == null) {
      showMessage("Please select a product", Colors.orange);
      return;
    }

    // Validate quantity (float)
    final enteredQuantity = double.tryParse(quantityController.text.trim());
    if (enteredQuantity == null || enteredQuantity <= 0) {
      showMessage("Enter a valid quantity", Colors.orange);
      return;
    }

    if (enteredQuantity > availableStock) {
      showMessage(
        "Not enough stock. Available: ${fmtQty(availableStock)}",
        Colors.red,
      );
      return;
    }

    setState(() => savingSale = true);

    try {
      final productId = selectedProduct!['id'];

      // Fetch latest product data
      final latestProduct = await supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      final latestStock =
          (latestProduct['quantity'] as num).toDouble();
      final latestBuyingPrice =
          (latestProduct['buying_price'] as num).toDouble();
      final latestSellingPrice =
          (latestProduct['selling_price'] as num).toDouble();

      if (enteredQuantity > latestStock) {
        throw Exception(
          "Not enough stock. Only ${fmtQty(latestStock)} available.",
        );
      }

      final total = latestSellingPrice * enteredQuantity;
      final profit =
          (latestSellingPrice - latestBuyingPrice) * enteredQuantity;

      // ---- 1. CREATE SALE (header) ----
      final sale = await supabase
          .from('sales')
          .insert({
            'total_amount': total,
            'total_profit': profit,
          })
          .select()
          .single();

      final saleId = sale['id'];

      // ---- 2. CREATE SALE ITEM (line) ----
      await supabase.from('sale_items').insert({
        'sale_id': saleId,
        'product_id': productId,
        'product_name': latestProduct['name'],
        'quantity': enteredQuantity,
        'buying_price': latestBuyingPrice,
        'selling_price': latestSellingPrice,
        'total': total,
        'profit': profit,
      });

      // ---- 3. UPDATE STOCK ----
      final newQuantity = latestStock - enteredQuantity;

      await supabase
          .from('products')
          .update({'quantity': newQuantity}).eq('id', productId);

      // ---- 4. RESET FORM ----
      quantityController.clear();
      setState(() {
        selectedProduct = null;
        quantity = 1.0;
      });

      // ---- 5. REFRESH ----
      await loadProducts();
      await loadTodaySales();

      if (!mounted) return;
      showMessage("Sale recorded successfully!", Colors.green);
    } catch (e) {
      if (!mounted) return;
      showMessage("Failed to record sale: $e", Colors.red);
    } finally {
      if (mounted) setState(() => savingSale = false);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  void showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String money(double amount) => "TZS ${amount.toStringAsFixed(0)}";

  String fmtQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }

  String fmtTime(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              loadProducts();
              loadTodaySales();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadProducts();
          await loadTodaySales();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==========================================
            // RECORD SALE CARD
            // ==========================================
            _recordSaleCard(),

            const SizedBox(height: 25),

            // ==========================================
            // TODAY'S SALES HEADER
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Sales",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (todaySales.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${todaySales.length} record${todaySales.length == 1 ? '' : 's'}",
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ==========================================
            // SUMMARY BAR
            // ==========================================
            if (todaySales.isNotEmpty) _summaryBar(),

            const SizedBox(height: 10),

            // ==========================================
            // SALES LIST
            // ==========================================
            if (todaySales.isEmpty)
              _emptyState()
            else
              ...todaySales.map(_saleCard),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: RECORD SALE CARD
  // ============================================================
  Widget _recordSaleCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Record Sale",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Enter the product that has been sold",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // PRODUCT
            const Text(
              "Product",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: selectedProduct,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: "Select product",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: products.map((product) {
                      final stock =
                          (product['quantity'] as num).toDouble();
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: product,
                        child: Text(
                          "${product['name']}  •  Stock: ${fmtQty(stock)}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (product) {
                      setState(() {
                        selectedProduct = product;
                        quantityController.clear();
                        quantity = 1.0;
                      });
                    },
                  ),

            const SizedBox(height: 20),

            // QUANTITY (float supported)
            const Text(
              "Quantity Sold",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "Enter quantity (e.g. 1.5)",
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => quantity = double.tryParse(value) ?? 0.0);
              },
            ),

            const SizedBox(height: 20),

            // INFO PANEL
            if (selectedProduct != null) _infoPanel(),

            const SizedBox(height: 20),

            // RECORD BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: savingSale ? null : recordSale,
                icon: savingSale
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(savingSale ? "Saving..." : "RECORD SALE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: INFO PANEL
  // ============================================================
  Widget _infoPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _infoRow("Available Stock", fmtQty(availableStock)),
          const SizedBox(height: 10),
          _infoRow("Selling Price", money(sellingPrice)),
          const SizedBox(height: 10),
          _infoRow(
            "Total",
            money(totalAmount),
            valueStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(
            "Profit",
            money(totalProfit),
            valueStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: SUMMARY BAR
  // ============================================================
  Widget _summaryBar() {
    return Card(
      color: Colors.deepPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _summaryTile("Items", fmtQty(todayTotalItems)),
            _summaryTile("Sales", money(todayTotalSales)),
            _summaryTile("Profit", money(todayTotalProfit)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: EMPTY STATE
  // ============================================================
  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(Icons.receipt_long,
                size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              "No sales recorded today",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: SINGLE SALE CARD
  // ============================================================
  Widget _saleCard(Map<String, dynamic> sale) {
    final name = sale['product_name']?.toString() ?? "Unknown";
    final soldQty = (sale['quantity'] as num?)?.toDouble() ?? 0;
    final unitPrice =
        (sale['selling_price'] as num?)?.toDouble() ?? 0;
    final total = (sale['total'] as num?)?.toDouble() ?? 0;
    final profit = (sale['profit'] as num?)?.toDouble() ?? 0;

    DateTime? created;
    if (sale['created_at'] != null) {
      created = DateTime.tryParse(sale['created_at'].toString());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child:
                      Icon(Icons.shopping_cart, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (created != null)
                  Text(
                    fmtTime(created.toLocal()),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // DETAILS
            _detailRow(
              "Quantity",
              "${fmtQty(soldQty)} × ${money(unitPrice)}",
            ),
            const SizedBox(height: 6),
            _detailRow(
              "Total",
              money(total),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            _detailRow(
              "Profit",
              money(profit),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            if (created != null) ...[
              const SizedBox(height: 6),
              Text(
                timeAgo(created.toLocal()),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ROW HELPERS
  // ============================================================
  Widget _infoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _summaryTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}