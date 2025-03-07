import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'food_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sugar_tracking_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _product;
  List<dynamic>? _searchResults;
  List<dynamic>? _searchHistory;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isOfflineMode = false;

  // Local cache for search history when offline
  final List<dynamic> _localSearchCache = [];

  @override
  void initState() {
    super.initState();
    // Set offline mode to false by default to ensure we try Firebase first
    _isOfflineMode = false;
    _checkFirebaseConnection();
  }

  // Check Firebase connection directly instead of general connectivity
  Future<void> _checkFirebaseConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to directly access Firestore to check connection
      await _firestore.collection('test_writes').doc('connection_test').set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test': 'Connectivity test successful'
      });

      print('Firebase connection successful');
      setState(() {
        _isOfflineMode = false;
      });

      // Load search history after confirming Firebase connection
      await _loadSearchHistory();
    } catch (e) {
      print('Firebase connection error: $e');
      setState(() {
        _isOfflineMode = true;
        _searchHistory = _localSearchCache;
      });

      // Show a message about being in offline mode
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Using offline mode. Search history stored locally.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get the document reference for the current user's search history
  DocumentReference _getUserHistoryRef() {
    final user = _auth.currentUser;
    // Always use email as the document ID for consistency
    if (user != null && user.email != null) {
      return _firestore.collection('search_history').doc(user.email);
    } else if (user != null) {
      // Fallback to UID if email is somehow null
      return _firestore.collection('search_history').doc(user.uid);
    } else {
      throw Exception('No authenticated user');
    }
  }

  // Load the user's search history from Firebase
  Future<void> _loadSearchHistory() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    // If we're offline, use local cache
    if (_isOfflineMode) {
      setState(() {
        _searchHistory = _localSearchCache;
        _isLoading = false;
      });
      print(
          'Offline mode: Using local search cache with ${_localSearchCache.length} items');
      return;
    }

    final user = _auth.currentUser;
    print('Current user: ${user?.email ?? "No user logged in"}');

    if (user != null) {
      try {
        // Always use the same document reference strategy
        final docRef = _getUserHistoryRef();
        print('Attempting to load search history from: ${docRef.path}');

        final doc = await docRef.get();

        if (doc.exists) {
          print('Search history document found');
          final data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('searches')) {
            print(
                'Search history contains ${(data['searches'] as List<dynamic>).length} items');

            // Update local cache first
            _localSearchCache.clear();
            List<dynamic> firebaseHistory = data['searches'] as List<dynamic>;
            _localSearchCache.addAll(firebaseHistory);

            setState(() {
              _searchHistory = List.from(_localSearchCache);
            });
            print(
                'Successfully loaded ${_searchHistory?.length} history items');
          } else {
            print(
                'Search history document exists but has no searches array or is malformed');
            print('Document data: $data');

            // Initialize an empty history
            setState(() {
              _searchHistory = [];
              _localSearchCache.clear();
            });

            // Fix the document structure
            await docRef.set({'email': user.email, 'searches': []});
          }
        } else {
          print('No search history document exists for this user');
          // Initialize an empty history
          setState(() {
            _searchHistory = [];
            _localSearchCache.clear();
          });

          // Create an empty history document
          await docRef.set({'email': user.email, 'searches': []});
          print('Created new empty search history for ${user.email}');
        }
      } catch (e) {
        print('Error loading search history: $e');
        setState(() {
          _errorMessage = 'Failed to load search history: $e';
          _isOfflineMode = true; // Set to offline mode if we can't load history
          _searchHistory = _localSearchCache;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading history: $e. Using offline mode.')),
        );
      }
    } else {
      print('Cannot load search history: User not logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to view search history')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Save search query to Firebase
  Future<void> _saveSearchToHistory(String query, {String? barcode}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final searchData = {
      'query': query,
      'timestamp': timestamp,
      'type': barcode != null ? 'barcode' : 'text',
      if (barcode != null) 'barcode': barcode,
    };

    print('Preparing to save search: $query');

    // Always save to local cache first
    _localSearchCache.insert(0, searchData);
    if (_localSearchCache.length > 20) {
      _localSearchCache.removeRange(20, _localSearchCache.length);
    }

    // Update the UI immediately with local cache
    setState(() {
      _searchHistory = List.from(_localSearchCache);
    });

    // If offline, don't attempt to save to Firebase
    if (_isOfflineMode) {
      print('Device is offline. Search saved to local cache only.');
      return;
    }

    final user = _auth.currentUser;
    print('Saving search for user: ${user?.email ?? "No user logged in"}');

    if (user != null && user.email != null) {
      try {
        // Get current history document
        final docRef = _getUserHistoryRef();
        print('Saving search to document: ${docRef.path}');

        final doc = await docRef.get();

        if (doc.exists) {
          // Update existing history
          final data = doc.data() as Map<String, dynamic>?;
          List<dynamic> searches = [];

          if (data != null && data.containsKey('searches')) {
            searches =
            List<dynamic>.from(data['searches'] as List<dynamic>? ?? []);
          }

          searches.insert(0, searchData); // Add new search at beginning

          // Limit to 20 most recent searches
          if (searches.length > 20) {
            searches = searches.sublist(0, 20);
          }

          print('Updating search history with ${searches.length} items');
          await docRef.update({'searches': searches});
          print('Successfully updated search history with new search: $query');
        } else {
          // Create new history document
          print('Creating new search history document');
          await docRef.set({
            'email': user.email,
            'searches': [searchData]
          });
          print(
              'Successfully created new search history document with first search: $query');
        }
      } catch (e) {
        print('Error saving search history: $e');
        // Set to offline mode if we can't save to Firebase
        setState(() {
          _isOfflineMode = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving to cloud. Using offline mode: $e')),
        );
      }
    } else {
      print('Cannot save search: User not logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save searches')),
      );
    }
  }

  // Function to fetch product by barcode
  Future<void> _fetchProductByBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = null;
    });

    try {
      final product = await _foodService.fetchProductByBarcode(barcode);
      print('Product fetched by barcode');

      // Save to history
      await _saveSearchToHistory('Barcode: $barcode', barcode: barcode);

      setState(() {
        _product = product as Map<String, dynamic>?;
      });
    } catch (e) {
      print('Error fetching product by barcode: $e');
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
      print('Search results found');

      // Save to history
      await _saveSearchToHistory(query);

      // Cast the results to the proper type
      final resultsMap = results;
      setState(() {
        _searchResults = resultsMap['products'] as List<dynamic>?;
      });
    } catch (e) {
      print('Error searching products by name: $e');
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
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a product name or barcode')),
      );
      return;
    }

    // Check if the input is a numeric barcode (usually 8, 12, or 13 digits)
    final barcodeRegex = RegExp(r'^\d{8,14}$');

    if (barcodeRegex.hasMatch(query)) {
      // If input matches barcode pattern, search by barcode
      print('Searching by barcode: $query');
      _fetchProductByBarcode(query);
    } else {
      // Otherwise, search by product name
      print('Searching by product name: $query');
      _searchProductsByName(query);
    }
  }

  // Function to scan barcode
  Future<void> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        print('Barcode scanned: ${result.rawContent}');
        _fetchProductByBarcode(result.rawContent);
      } else {
        print('Empty barcode scan result');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No barcode detected')),
        );
      }
    } catch (e) {
      print('Error scanning barcode: $e');
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
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              _showSearchHistory();
            },
          ),
          IconButton(
            icon: Icon(Icons.show_chart),
            onPressed: () {
              // Navigate to Sugar Tracking Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SugarTrackingScreen()),
              );
            },
          ),
          if (_isOfflineMode)
            IconButton(
              icon: Icon(Icons.cloud_off),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'App is currently in offline mode. Attempting to reconnect...')),
                );
                _checkFirebaseConnection();
              },
            ),
          // Add a sync button to force firebase sync
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              _forceSyncWithFirebase();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Enter your product to check the sugar level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    // Set a fixed height for the TextField
                    maxHeight: 60,
                    // Set a minimum and maximum width based on screen constraints
                    minWidth: constraints.maxWidth * 0.8,
                    maxWidth: constraints.maxWidth * 0.9,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter product name or barcode',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search,
                            color: Theme.of(context).iconTheme.color),
                        onPressed: _handleSearch,
                      ),
                    ),
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _handleSearch,
                      child: Text('Search'),
                      style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _scanBarcode,
                      child: Text('Scan Barcode'),
                      style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                if (_isOfflineMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Offline Mode: Search history stored locally',
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            _checkFirebaseConnection();
                          },
                          child: Text('Reconnect',
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 10),
                Expanded(
                  child: _buildResults(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Force synchronization with Firebase
  Future<void> _forceSyncWithFirebase() async {
    if (_isOfflineMode) {
      // First try to re-establish connection
      await _checkFirebaseConnection();

      // If still offline, show message and return
      if (_isOfflineMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Cannot sync while offline. Please check your connection.')),
        );
        return;
      }
    }

    if (_localSearchCache.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No local searches to sync')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        final docRef = _getUserHistoryRef();

        // Replace the entire searches array with our local cache
        await docRef.set(
            {'email': user.email, 'searches': _localSearchCache},
            SetOptions(
                merge: true)); // Use merge true to avoid losing other fields

        print(
            'Successfully synced ${_localSearchCache.length} searches to Firebase');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search history synced successfully')),
        );

        // Reload from Firebase to confirm sync worked
        await _loadSearchHistory();
      } catch (e) {
        print('Error syncing with Firebase: $e');
        setState(() {
          _isOfflineMode = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing with Firebase: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to sync with cloud')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show search history dialog
  void _showSearchHistory() {
    // Check if we should try to load history first (if empty)
    if (_searchHistory == null || _searchHistory!.isEmpty) {
      if (!_isOfflineMode) {
        // Try to load history if we're online but don't have history
        _loadSearchHistory().then(() {
          if (_searchHistory == null || _searchHistory!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No search history found')),
            );
          } else {
            // Now show the dialog since we have history
            _displaySearchHistoryDialog();
          }
        } as FutureOr Function(void value));
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No search history found')),
        );
        return;
      }
    }

    // If we have history, display it
    _displaySearchHistoryDialog();
  }

  // Separate method to display the search history dialog
  void _displaySearchHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('Search History'),
            if (_isOfflineMode) ...[
              SizedBox(width: 8),
              Icon(Icons.cloud_off, color: Colors.orange, size: 16),
            ],
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _searchHistory!.length,
            itemBuilder: (context, index) {
              final search = _searchHistory![index] as Map<String, dynamic>;
              final String query = search['query'] as String? ?? 'Unknown';
              final int timestamp = search['timestamp'] as int? ?? 0;
              final DateTime date =
              DateTime.fromMillisecondsSinceEpoch(timestamp);
              final formattedDate =
                  '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

              return ListTile(
                title: Text(query),
                subtitle: Text(formattedDate),
                leading: Icon(
                  search['type'] == 'barcode' ? Icons.qr_code : Icons.search,
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (search['type'] == 'barcode' &&
                      search['barcode'] != null) {
                    _fetchProductByBarcode(search['barcode'] as String);
                  } else {
                    _searchController.text = query.replaceAll('Barcode: ', '');
                    if (query.startsWith('Barcode: ')) {
                      _fetchProductByBarcode(query.replaceAll('Barcode: ', ''));
                    } else {
                      _searchProductsByName(query);
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          if (_isOfflineMode)
            TextButton(
              child: Text('Connect to Cloud'),
              onPressed: () async {
                Navigator.pop(context);
                await _checkFirebaseConnection();
                if (!_isOfflineMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Connected! Search history synced with cloud.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                        Text('Still offline. Using local history cache.')),
                  );
                }
              },
            ),
          TextButton(
            child: Text('Force Sync'),
            onPressed: () {
              Navigator.pop(context);
              _forceSyncWithFirebase();
            },
          ),
          TextButton(
            child: Text('Clear History'),
            onPressed: () {
              _clearSearchHistory();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Clear search history
  Future<void> _clearSearchHistory() async {
    // Always clear local cache
    setState(() {
      _localSearchCache.clear();
      _searchHistory = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Search history cleared')),
    );

    // If offline, don't try to clear from Firebase
    if (_isOfflineMode) {
      return;
    }

    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        await _getUserHistoryRef().update({'searches': []});
        print('Search history cleared for user: ${user.email}');
      } catch (e) {
        print('Error clearing search history in Firebase: $e');
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cloud data: $e')),
        );
      }
    }
  }

  // Method to build and display results (existing implementation)
  Widget _buildResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
          child: Text(_errorMessage, style: TextStyle(color: Colors.red)));
    }

    // Display single product details
    if (_product != null && _product!.containsKey('product')) {
      final product = _product!['product'] as Map<String, dynamic>;
      return SingleChildScrollView(
        child: Card(
          elevation: 4,
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.containsKey('image_url') &&
                    product['image_url'] != null)
                  Center(
                    child: Image.network(
                      product['image_url'] as String,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 100),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  product['product_name'] as String? ?? 'Unknown Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Brand: ${product['brands'] as String? ?? 'N/A'}'),
                SizedBox(height: 4),
                _buildNutrientInfo(
                    'Sugar',
                    product.containsKey('nutriments')
                        ? (product['nutriments']
                    as Map<String, dynamic>)['sugars_100g']
                        : null),
                _buildNutrientInfo(
                    'Carbohydrates',
                    product.containsKey('nutriments')
                        ? (product['nutriments']
                    as Map<String, dynamic>)['carbohydrates_100g']
                        : null),
                _buildNutrientInfo(
                    'Fat',
                    product.containsKey('nutriments')
                        ? (product['nutriments']
                    as Map<String, dynamic>)['fat_100g']
                        : null),
                _buildNutrientInfo(
                    'Protein',
                    product.containsKey('nutriments')
                        ? (product['nutriments']
                    as Map<String, dynamic>)['proteins_100g']
                        : null),
                SizedBox(height: 8),
                Text(
                    'Ingredients: ${product['ingredients_text'] as String? ?? 'N/A'}'),
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
          final product = _searchResults![index] as Map<String, dynamic>;
          return ListTile(
            leading:
            product.containsKey('image_url') && product['image_url'] != null
                ? Image.network(
              product['image_url'] as String,
              width: 50,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.image_not_supported),
            )
                : Icon(Icons.food_bank),
            title:
            Text(product['product_name'] as String? ?? 'Unknown Product'),
            subtitle: Text(product['brands'] as String? ?? 'Unknown Brand'),
            onTap: () {
              if (product.containsKey('code') && product['code'] != null) {
                _fetchProductByBarcode(product['code'] as String);
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

  // Nutrient info builder method
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