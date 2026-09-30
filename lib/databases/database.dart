import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Products
  Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await client.from('products').select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addProduct({
    required String name,
    required String description,
    required double buyingPrice,
    required double sellingPrice,
    required int quantity,
  }) async {
    await client.from('products').insert({
      'name': name,
      'description': description,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
    });
  }

  Future<void> updateProduct(
    String id,
    Map<String, dynamic> values,
  ) async {
    await client.from('products').update(values).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }
}