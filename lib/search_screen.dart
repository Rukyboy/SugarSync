import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart'; // For barcode scanning
import 'food_service.dart'; // Import the FoodService

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _product;
  List<dynamic>? _searchResults;
  bool _isLoading = false;
  String _errorMessage = '';

  // Function to fetch product by barcode
  Future<void> _fetchProductByBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = null;
    });

    try {
      final product = await _foodService.fetchProductByBarcode(barcode);
      setState(() {
        _product = product;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to search products by name
  Future<void> _searchProductsByName(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _product = null;
    });

    try {
      final results = await _foodService.searchProducts(query);
      setState(() {
        _searchResults = results['products'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to handle search input and determine if it's a barcode or product name
  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Check if the input is a numeric barcode (usually 8, 12, or 13 digits)
    final barcodeRegex = RegExp(r'^\d{8,14}$');

    if (barcodeRegex.hasMatch(query)) {
      // If input matches barcode pattern, search by barcode
      _fetchProductByBarcode(query);
    } else {
      // Otherwise, search by product name
      _searchProductsByName(query);
    }
  }

  // Function to scan barcode
  Future<void> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        _fetchProductByBarcode(result.rawContent);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning barcode: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Sugar Level'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Enter your product to check the sugar level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter product name or barcode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _handleSearch,
                ),
              ),
              onSubmitted: (_) => _handleSearch(),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _handleSearch,
                  child: Text('Search'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _scanBarcode,
                  child: Text('Scan Barcode'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)));
    }

    // Display single product details
    if (_product != null && _product!['product'] != null) {
      final product = _product!['product'];
      return SingleChildScrollView(
        child: Card(
          elevation: 4,
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product['image_url'] != null)
                  Center(
                    child: Image.network(
                      product['image_url'],
                      height: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 100),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  product['product_name'] ?? 'Unknown Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Brand: ${product['brands'] ?? 'N/A'}'),
                SizedBox(height: 4),
                _buildNutrientInfo('Sugar', product['nutriments']?['sugars_100g']),
                _buildNutrientInfo('Carbohydrates', product['nutriments']?['carbohydrates_100g']),
                _buildNutrientInfo('Fat', product['nutriments']?['fat_100g']),
                _buildNutrientInfo('Protein', product['nutriments']?['proteins_100g']),
                SizedBox(height: 8),
                Text('Ingredients: ${product['ingredients_text'] ?? 'N/A'}'),
              ],
            ),
          ),
        ),
      );
    }

    // Display search results list
    if (_searchResults != null && _searchResults!.isNotEmpty) {
      return ListView.builder(
        itemCount: _searchResults!.length,
        itemBuilder: (context, index) {
          final product = _searchResults![index];
          return ListTile(
            leading: product['image_url'] != null
                ? Image.network(
              product['image_url'],
              width: 50,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.image_not_supported),
            )
                : Icon(Icons.food_bank),
            title: Text(product['product_name'] ?? 'Unknown Product'),
            subtitle: Text(product['brands'] ?? 'Unknown Brand'),
            onTap: () {
              if (product['code'] != null) {
                _fetchProductByBarcode(product['code']);
              }
            },
          );
        },
      );
    }

    // No results state
    return Center(
      child: Text('Search for a product by name or barcode'),
    );
  }

  Widget _buildNutrientInfo(String name, dynamic value) {
    final displayValue = value != null ? '$value g per 100g' : 'N/A';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$name: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(displayValue),
        ],
      ),
    );
  }
}