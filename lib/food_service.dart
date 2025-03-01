import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodService {
  // Base URL for the Open Food Facts API
  static const String baseUrl = 'https://world.openfoodfacts.org';

  // Fetch product details by barcode
  Future<Map<String, dynamic>> fetchProductByBarcode(String barcode) async {
    final url = Uri.parse('$baseUrl/api/v0/product/$barcode.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Parse the JSON response
      final data = json.decode(response.body);

      // Check if the product exists
      if (data['status'] == 1) {
        return data;
      } else {
        throw Exception('Product not found');
      }
    } else {
      // If the request fails, throw an exception
      throw Exception('Failed to load product details');
    }
  }

  // Search for products by name using the suggested URL format
  Future<Map<String, dynamic>> searchProducts(String query) async {
    // URL encode the search query for safe transmission
    final encodedQuery = Uri.encodeComponent(query);

    // Using the suggested URL format with search_simple=1 parameter
    final url = Uri.parse('$baseUrl/cgi/search.pl?search_terms=$encodedQuery&search_simple=1&json=1');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      // If the request is successful, parse the JSON response
      return json.decode(response.body);
    } else {
      // If the request fails, throw an exception
      throw Exception('Failed to search products');
    }
  }
}