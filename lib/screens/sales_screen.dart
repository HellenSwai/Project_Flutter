import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> todaySales = [];

  Map<String, dynamic>? selectedProduct;

  final quantityController = TextEditingController();

  bool loadingProducts = true;
  bool savingSale = false;

  int quantity = 1;

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

  // LOAD PRODUCTS

  Future<void> loadProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select()
          .order('name');

      if (!mounted) return;

      setState(() {
        products = List<Map<String, dynamic>>.from(data);
        loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingProducts = false;
      });

      showMessage(
        "Failed to load products: $e",
        Colors.red,
      );
    }
  }

  // LOAD TODAY'S SALES

  Future<void> loadTodaySales() async {
    try {
      final now = DateTime.now();

      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final data = await supabase
          .from('sale_items')
          .select()
          .gte(
            'created_at',
            startOfDay.toIso8601String(),
          )
          .order(
            'created_at',
            ascending: false,
          );

      if (!mounted) return;

      setState(() {
        todaySales = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Failed to load sales: $e",
        Colors.red,
      );
    }
  }

  // CALCULATIONS

  double get sellingPrice {
    if (selectedProduct == null) {
      return 0;
    }

    return (selectedProduct!['selling_price'] as num)
        .toDouble();
  }

  double get buyingPrice {
    if (selectedProduct == null) {
      return 0;
    }

    return (selectedProduct!['buying_price'] as num)
        .toDouble();
  }

  double get totalAmount {
    return sellingPrice * quantity;
  }

  double get totalProfit {
    return (sellingPrice - buyingPrice) * quantity;
  }

  int get availableStock {
    if (selectedProduct == null) {
      return 0;
    }

    return (selectedProduct!['quantity'] as num).toInt();
  }

  // RECORD SALE

  Future<void> recordSale() async {
    if (selectedProduct == null) {
      showMessage(
        "Please select a product",
        Colors.orange,
      );
      return;
    }

    final enteredQuantity =
        int.tryParse(quantityController.text.trim());

    if (enteredQuantity == null || enteredQuantity <= 0) {
      showMessage(
        "Enter a valid quantity",
        Colors.orange,
      );
      return;
    }

    if (enteredQuantity > availableStock) {
      showMessage(
        "Not enough stock. Available: $availableStock",
        Colors.red,
      );
      return;
    }

    setState(() {
      savingSale = true;
    });

    try {
      final productId = selectedProduct!['id'];

      // Get latest product information
      final latestProduct = await supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      final latestStock =
          (latestProduct['quantity'] as num).toInt();

      final latestBuyingPrice =
          (latestProduct['buying_price'] as num).toDouble();

      final latestSellingPrice =
          (latestProduct['selling_price'] as num).toDouble();

      if (enteredQuantity > latestStock) {
        throw Exception(
          "Not enough stock. Only $latestStock available.",
        );
      }

      final total =
          latestSellingPrice * enteredQuantity;

      final profit =
          (latestSellingPrice - latestBuyingPrice) *
              enteredQuantity;

      // CREATE SALE


      final sale = await supabase
          .from('sales')
          .insert({
            'total_amount': total,
            'total_profit': profit,
          })
          .select()
          .single();

      final saleId = sale['id'];

      // CREATE SALE ITEM

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


      // UPDATE PRODUCT STOCK

      final newQuantity =
          latestStock - enteredQuantity;

      await supabase
          .from('products')
          .update({
            'quantity': newQuantity,
          })
          .eq('id', productId);

      // REFRESH

      quantityController.clear();

      setState(() {
        selectedProduct = null;
        quantity = 1;
      });

      await loadProducts();
      await loadTodaySales();

      if (!mounted) return;

      showMessage(
        "Sale recorded successfully!",
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Failed to record sale: $e",
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          savingSale = false;
        });
      }
    }
  }

  // MESSAGE

  void showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // MONEY FORMAT

  String money(double amount) {
    return "TZS ${amount.toStringAsFixed(0)}";
  }

  // BUILD

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

            // RECORD SALE

            Card(
              elevation: 4,

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Record Sale",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Enter the product that has been sold",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PRODUCT
                    const Text(
                      "Product",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    loadingProducts
                        ? const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        : DropdownButtonFormField<
                            Map<String, dynamic>>(
                            initialValue:
                                selectedProduct,

                            isExpanded: true,

                            decoration:
                                InputDecoration(
                              hintText:
                                  "Select product",

                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  10,
                                ),
                              ),
                            ),

                            items:
                                products.map((product) {
                              final stock =
                                  (product['quantity']
                                          as num)
                                      .toInt();

                              return DropdownMenuItem<
                                  Map<String, dynamic>>(
                                value: product,

                                child: Text(
                                  "${product['name']}  •  Stock: $stock",
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),

                            onChanged: (product) {
                              setState(() {
                                selectedProduct =
                                    product;

                                quantityController
                                    .clear();

                                quantity = 1;
                              });
                            },
                          ),

                    const SizedBox(height: 20),

                    // QUANTITY
                    const Text(
                      "Quantity Sold",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          quantityController,

                      keyboardType:
                          TextInputType.number,

                      decoration: InputDecoration(
                        hintText:
                            "Enter quantity",

                        prefixIcon:
                            const Icon(
                          Icons.numbers,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),

                      onChanged: (value) {
                        setState(() {
                          quantity =
                              int.tryParse(value) ??
                                  1;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // PRODUCT INFORMATION
                    if (selectedProduct != null)
                      Container(
                        padding:
                            const EdgeInsets.all(15),

                        decoration: BoxDecoration(
                          color: Colors.deepPurple
                              .withValues(
                            alpha: 0.06,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),

                        child: Column(
                          children: [

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [
                                const Text(
                                  "Available Stock",
                                ),

                                Text(
                                  "$availableStock",

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [
                                const Text(
                                  "Selling Price",
                                ),

                                Text(
                                  money(
                                    sellingPrice,
                                  ),

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [
                                const Text(
                                  "Total",
                                ),

                                Text(
                                  money(
                                    totalAmount,
                                  ),

                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [
                                const Text(
                                  "Profit",
                                ),

                                Text(
                                  money(
                                    totalProfit,
                                  ),

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // RECORD BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child:
                          ElevatedButton.icon(
                        onPressed:
                            savingSale
                                ? null
                                : recordSale,

                        icon: savingSale
                            ? const SizedBox(
                                width: 20,
                                height: 20,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check,
                              ),

                        label: Text(
                          savingSale
                              ? "Saving..."
                              : "RECORD SALE",
                        ),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.deepPurple,

                          foregroundColor:
                              Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // TODAY'S SALES

            const Text(
              "Today's Sales",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (todaySales.isEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(25),

                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 50,
                        color:
                            Colors.grey.shade400,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "No sales recorded today",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...todaySales.map((sale) {
                final name =
                    sale['product_name']
                        .toString();

                final soldQuantity =
                    (sale['quantity'] as num)
                        .toInt();

                final total =
                    (sale['total'] as num)
                        .toDouble();

                final profit =
                    (sale['profit'] as num)
                        .toDouble();

                return Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      backgroundColor:
                          Colors.deepPurple,

                      child: Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                    ),

                    title: Text(name),

                    subtitle: Text(
                      "Quantity: $soldQuantity\n"
                      "Profit: ${money(profit)}",
                    ),

                    trailing: Text(
                      money(total),

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.deepPurple,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}