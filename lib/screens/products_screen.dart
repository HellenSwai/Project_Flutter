import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      products = List<Map<String, dynamic>>.from(data);
      filteredProducts = products;
    });
  }

  void searchProduct(String value) {
    setState(() {
      filteredProducts = products.where((product) {
        return product['name']
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase());
      }).toList();
    });
  }

  Future<void> addProduct(
    String name,
    double buyingPrice,
    double sellingPrice,
    int quantity,
  ) async {
    await supabase.from('products').insert({
      'name': name,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
    });

    loadProducts();
  }

  Future<void> updateProduct(
    String id,
    String name,
    double buyingPrice,
    double sellingPrice,
    int quantity,
  ) async {
    await supabase.from('products').update({
      'name': name,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
    }).eq('id', id);

    loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await supabase.from('products').delete().eq('id', id);

    loadProducts();
  }

  void showProductDialog({Map<String, dynamic>? product}) {
    final nameController =
        TextEditingController(text: product?['name'] ?? '');

    final buyingController =
        TextEditingController(text: product?['buying_price']?.toString() ?? '');

    final sellingController =
        TextEditingController(text: product?['selling_price']?.toString() ?? '');

    final quantityController =
        TextEditingController(text: product?['quantity']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product == null ? "Add Product" : "Edit Product"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: "Product Name"),
              ),

              TextField(
                controller: buyingController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Buying Price"),
              ),

              TextField(
                controller: sellingController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Selling Price"),
              ),

              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Quantity"),
              ),
            ],
          ),
        ),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {

              if (product == null) {
                await addProduct(
                  nameController.text,
                  double.parse(buyingController.text),
                  double.parse(sellingController.text),
                  int.parse(quantityController.text),
                );
              } else {
                await updateProduct(
                  product['id'],
                  nameController.text,
                  double.parse(buyingController.text),
                  double.parse(sellingController.text),
                  int.parse(quantityController.text),
                );
              }

              if (mounted) Navigator.pop(context);
            },
            child: Text(product == null ? "Save" : "Update"),
          ),
        ],
      ),
    );
  }

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
            "Are you sure you want to delete this product?"),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),

          ElevatedButton(
            onPressed: () async {
              await deleteProduct(id);

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Products"),
        backgroundColor: Colors.deepPurple,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: searchController,
              onChanged: searchProduct,
              decoration: InputDecoration(
                hintText: "Search product...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {

                  final product = filteredProducts[index];

                  return Card(
                    child: ListTile(

                      leading: const Icon(Icons.inventory),

                      title: Text(product['name']),

                      subtitle: Text(
                        "Buying: TZS ${product['buying_price']}\n"
                        "Selling: TZS ${product['selling_price']}\n"
                        "Stock: ${product['quantity']}",
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                            onPressed: () =>
                                showProductDialog(product: product),
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                confirmDelete(product['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => showProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}