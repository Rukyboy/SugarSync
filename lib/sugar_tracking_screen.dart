import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;

class SugarTrackingScreen extends StatefulWidget {
  const SugarTrackingScreen({Key? key}) : super(key: key);

  @override
  _SugarTrackingScreenState createState() => _SugarTrackingScreenState();
}

class _SugarTrackingScreenState extends State<SugarTrackingScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _sugarLevelController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _sugarLevels = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Pagination variables
  final int _pageSize = 15;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Ensure data is loaded after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSugarLevels();
    });
  }

  @override
  void dispose() {
    _sugarLevelController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreSugarLevels();
    }
  }

  Future<void> _loadSugarLevels() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _handleError('Please log in to view sugar levels');
        return;
      }

      // Log user details for debugging
      developer.log('Loading sugar levels for user: ${user.uid}',
          name: 'SugarTrackingScreen',
          error: 'User Email: ${user.email}'
      );

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Ensure user document exists or create it if not
      final userDocRef = _firestore.collection('sugar_levels').doc(user.uid);

      // Check if user document exists, if not create it
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        await userDocRef.set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid
        }, SetOptions(merge: true)); // Use merge to prevent overwriting existing data
      }

      // Construct query to get user's sugar levels
      Query query = userDocRef
          .collection('levels')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      final querySnapshot = await query.get();

      // Log query results for debugging
      developer.log('Query snapshot length: ${querySnapshot.docs.length}',
          name: 'SugarTrackingScreen'
      );

      // Add null checks and type conversions
      final levels = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'level': (data['level'] is num) ? data['level'] : 0.0,
          'timestamp': (data['timestamp'] is Timestamp)
              ? data['timestamp']
              : Timestamp.now(),
          'id': doc.id,
        };
      }).toList();

      setState(() {
        _sugarLevels = levels;
        _lastDocument = querySnapshot.docs.isNotEmpty
            ? querySnapshot.docs.last
            : null;
        _hasMoreData = querySnapshot.docs.length == _pageSize;
        _isLoading = false;
      });

      // Log final sugar levels for debugging
      developer.log('Sugar levels loaded: ${_sugarLevels.length}',
          name: 'SugarTrackingScreen'
      );
    } catch (e) {
      // Log detailed error information
      developer.log('Error loading sugar levels',
          name: 'SugarTrackingScreen',
          error: e,
          stackTrace: StackTrace.current
      );

      _handleError('Failed to load sugar levels. Please try again.');
    }
  }

  Future<void> _loadMoreSugarLevels() async {
    if (!_hasMoreData || _isLoading || _isLoadingMore) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      if (_lastDocument == null) {
        setState(() {
          _isLoadingMore = false;
        });
        return;
      }

      Query query = _firestore
          .collection('sugar_levels')
          .doc(user.uid)
          .collection('levels')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final querySnapshot = await query.get();

      // Add null checks and type conversions
      final newLevels = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'level': (data['level'] is num) ? data['level'] : 0.0,
          'timestamp': (data['timestamp'] is Timestamp)
              ? data['timestamp']
              : Timestamp.now(),
          'id': doc.id,
        };
      }).toList();

      setState(() {
        _sugarLevels.addAll(newLevels);
        _lastDocument = querySnapshot.docs.isNotEmpty
            ? querySnapshot.docs.last
            : null;
        _hasMoreData = querySnapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _handleError('Error loading more sugar levels');
    }
  }

  void _handleError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isLoadingMore = false;
    });

    // Use ScaffoldMessenger only if context is available
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _addSugarLevel() async {
    final user = _auth.currentUser;
    if (user == null) {
      _handleError('Please log in to add sugar level');
      return;
    }

    final levelText = _sugarLevelController.text.trim();
    final level = double.tryParse(levelText);

    if (level == null || level <= 0) {
      _handleError('Please enter a valid sugar level');
      return;
    }

    if (level > 500) {
      _handleError('Sugar level must be below 500 mg/dL');
      return;
    }

    try {
      await _firestore
          .collection('sugar_levels')
          .doc(user.uid)
          .collection('levels')
          .add({
        'level': level,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _sugarLevelController.clear();
      await _loadSugarLevels(); // Reload levels after adding

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sugar level added successfully')),
        );
      }
    } catch (e) {
      _handleError('Failed to add sugar level: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: Text('Sugar Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _resetSugarLevels,
            tooltip: 'Reset Levels',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSugarLevels,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sugarLevelController,
                        decoration: InputDecoration(
                          labelText: 'Sugar Level (mg/dL)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addSugarLevel,
                      child: Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_sugarLevels.isEmpty) {
      return Center(
        child: Text(
          'No sugar levels recorded. Add your first level!',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      children: [
        _buildSugarLevelBarChart(),
        _buildSugarLevelsList(),
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSugarLevelBarChart() {
    // Prevent crash with empty data
    if (_sugarLevels.isEmpty) {
      return SizedBox.shrink();
    }

    final levels = _sugarLevels.map((e) => e['level'] as num).toList();
    final maxLevel = levels.reduce((a, b) => a > b ? a : b);
    final maxY = (maxLevel > 300) ? (maxLevel * 1.1).ceilToDouble() : 300.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: _sugarLevels.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: (entry.value['level'] as num).toDouble(),
                    color: _getColorForSugarLevel(entry.value['level']),
                    width: 10,
                  )
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= _sugarLevels.length) return Text('');
                    final date = (_sugarLevels[index]['timestamp'] as Timestamp).toDate();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('MM/dd').format(date),
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Color _getColorForSugarLevel(num level) {
    if (level < 70) return Colors.blue; // Low
    if (level >= 70 && level <= 140) return Colors.green; // Normal
    if (level > 140 && level <= 200) return Colors.orange; // Prediabetes
    return Colors.red; // High
  }

  Widget _buildSugarLevelsList() {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _sugarLevels.length,
        itemBuilder: (context, index) {
          final level = _sugarLevels[index];
          final date = (level['timestamp'] as Timestamp).toDate();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorForSugarLevel(level['level']),
              child: Text(
                (level['level'] as num).toStringAsFixed(1),
                style: TextStyle(color: Colors.white),
              ),
            ),
            title: Text(DateFormat('MMMM dd, yyyy - hh:mm a').format(date)),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSugarLevel(level['id']),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteSugarLevel(String docId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _handleError('Please log in to delete sugar level');
      return;
    }

    try {
      await _firestore
          .collection('sugar_levels')
          .doc(user.uid)
          .collection('levels')
          .doc(docId)
          .delete();

      await _loadSugarLevels();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sugar level deleted successfully')),
        );
      }
    } catch (e) {
      _handleError('Failed to delete sugar level: ${e.toString()}');
    }
  }

  Future<void> _resetSugarLevels() async {
    final user = _auth.currentUser;
    if (user == null) {
      _handleError('Please log in to reset sugar levels');
      return;
    }

    bool? confirmReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Sugar Levels'),
        content: Text('Delete all sugar level records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmReset == true) {
      try {
        final querySnapshot = await _firestore
            .collection('sugar_levels')
            .doc(user.uid)
            .collection('levels')
            .get();

        // Use batched writes for better performance
        WriteBatch batch = _firestore.batch();
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        setState(() {
          _sugarLevels.clear();
          _lastDocument = null;
          _hasMoreData = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sugar levels reset')),
          );
        }
      } catch (e) {
        _handleError('Failed to reset sugar levels: ${e.toString()}');
      }
    }
  }
}