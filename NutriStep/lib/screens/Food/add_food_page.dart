import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'food_detail_page.dart';
import 'myfood.dart';

class AddFoodPage extends StatefulWidget {
  final String mealType;
  final String userId;

  const AddFoodPage({
    super.key,
    required this.mealType,
    required this.userId,
  });

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DocumentSnapshot> recentFoods = [];
  List<DocumentSnapshot> suggestedFoods = [];
  List<DocumentSnapshot> filteredFoods = [];
  bool showOtherOption = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchFoods();
    _searchController.addListener(() {
      handleSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchFoods() async {
    final userId = widget.userId;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final suggestionSnapshot = await FirebaseFirestore.instance
        .collection('foods')
        .limit(12)
        .get();

    final recentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('logs')
        .doc(today)
        .collection(widget.mealType)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    setState(() {
      suggestedFoods = suggestionSnapshot.docs;
      recentFoods = recentSnapshot.docs;
      filteredFoods = suggestedFoods;
      showOtherOption = false;
    });
  }

  void handleSearch(String query) {
    setState(() {
      searchQuery = query.trim();
      if (query.isEmpty) {
        filteredFoods = suggestedFoods;
        showOtherOption = false;
      } else {
        filteredFoods = suggestedFoods
            .where((doc) =>
            (doc.data()! as Map<String, dynamic>)['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
        showOtherOption = filteredFoods.isEmpty;
      }
    });
  }

  Widget _buildFoodCard(DocumentSnapshot food) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = food.data()! as Map<String, dynamic>;
    final name = data['name'] ?? '';
    final calories = data['calories'] ?? 0;
    final serving = data['serving_size'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "$calories cal · $serving",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: colorScheme.primary, size: 28),
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => FoodDetailPage(
                  foodData: data,
                  mealType: widget.mealType,
                  userId: widget.userId,
                ),
              ),
            );

            if (result == true) {
              Navigator.pop(context, true);
            }
          },
        ),
      ),
    );
  }

  Future<bool?> showAddOtherDialog({String? initialName}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final _nameController = TextEditingController(text: initialName ?? '');
    final _calController = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Add Custom Food",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: "Name",
                hintText: 'Enter food name',
                labelStyle: theme.inputDecorationTheme.labelStyle,
                hintStyle: theme.inputDecorationTheme.hintStyle,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _calController,
              keyboardType: TextInputType.number,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: "Calories",
                hintText: 'Enter calories',
                labelStyle: theme.inputDecorationTheme.labelStyle,
                hintStyle: theme.inputDecorationTheme.hintStyle,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = _nameController.text.trim();
              final cal = double.tryParse(_calController.text.trim());
              if (name.isEmpty || cal == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please enter valid name and calories.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onError,
                      ),
                    ),
                    backgroundColor: colorScheme.error,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final today = DateTime.now().toIso8601String().substring(0, 10);
              final ref = FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.userId)
                  .collection("logs")
                  .doc(today)
                  .collection("others");

              await ref.add({
                "name": name,
                "calories": cal,
                "servings": 1,
                "total_calories": cal,
                "timestamp": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context, true);
            },
            child: Text(
              "Add",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      colors: [colorScheme.primary, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            widget.mealType.capitalize(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.primary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          labelStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: "All Foods"),
            Tab(text: "My Foods"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "Search for foods...",
                hintStyle: theme.inputDecorationTheme.hintStyle,
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () {
                    _searchController.clear();
                    handleSearch('');
                  },
                )
                    : null,
                filled: theme.inputDecorationTheme.filled,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
              ),
            ),
          ),
          if (showOtherOption)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final result = await showAddOtherDialog(initialName: searchQuery);
                  if (result == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Add “$searchQuery” as custom food",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: fetchFoods,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (recentFoods.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Recently Added",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...recentFoods.map(_buildFoodCard).toList(),
                        Divider(color: colorScheme.onSurface.withOpacity(0.3)),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Suggestions",
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...filteredFoods.map(_buildFoodCard).toList(),
                    ],
                  ),
                ),
                MyFoodsTab(
                  mealType: widget.mealType,
                  userId: widget.userId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}