import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'food_detail_page.dart';

class MyFoodsTab extends StatefulWidget {
  final String mealType;
  final String userId;

  const MyFoodsTab({
    super.key,
    required this.mealType,
    required this.userId,
  });

  @override
  State<MyFoodsTab> createState() => _MyFoodsTabState();
}

class _MyFoodsTabState extends State<MyFoodsTab> {
  void _showCreateMyFoodDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final carbController = TextEditingController();
    final fatController = TextEditingController();
    final proteinController = TextEditingController();
    final servingController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Create New Food",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField("Name", nameController),
              const SizedBox(height: 8),
              _buildDialogTextField("Calories", calController, keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _buildDialogTextField("Carbohydrates (g)", carbController, keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _buildDialogTextField("Fat (g)", fatController, keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _buildDialogTextField("Protein (g)", proteinController, keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _buildDialogTextField("Serving Size", servingController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              final name = nameController.text.trim();
              final calories = double.tryParse(calController.text.trim()) ?? 0;
              final carbs = double.tryParse(carbController.text.trim()) ?? 0;
              final fat = double.tryParse(fatController.text.trim()) ?? 0;
              final protein = double.tryParse(proteinController.text.trim()) ?? 0;
              final servingSize = servingController.text.trim();

              if (name.isNotEmpty && servingSize.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.userId)
                    .collection("my_foods")
                    .add({
                  "name": name,
                  "calories": calories,
                  "serving_size": servingSize,
                  "nutrients": {
                    "carbohydrates": carbs,
                    "fat": fat,
                    "protein": protein,
                  },
                  "created_at": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Food created successfully!",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: colorScheme.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please enter a name and serving size.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onError,
                      ),
                    ),
                    backgroundColor: colorScheme.error,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              "Create",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter $label',
        labelStyle: theme.inputDecorationTheme.labelStyle,
        hintStyle: theme.inputDecorationTheme.hintStyle,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Foods",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateMyFoodDialog,
                  icon: Icon(Icons.restaurant_menu, size: 20, color: colorScheme.onPrimary),
                  label: Text(
                    "Create",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('my_foods')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  );
                }

                final foods = snapshot.data!.docs;
                if (foods.isEmpty) {
                  return Center(
                    child: Text(
                      "No custom foods yet.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final doc = foods[index];
                      final data = doc.data()! as Map<String, dynamic>;

                      final name = data['name'] ?? '';
                      final calories = (data['calories'] ?? 0).toString();
                      final serving = data['serving_size'] ?? '-';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: Card(
                          color: colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: IconButton(
                              icon: Icon(Icons.delete, color: colorScheme.error, size: 28),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(widget.userId)
                                    .collection("my_foods")
                                    .doc(doc.id)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Food deleted",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                    backgroundColor: colorScheme.primary,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            title: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "$calories cal · $serving",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.add_circle, color: colorScheme.primary, size: 28),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FoodDetailPage(
                                      foodData: data,
                                      mealType: widget.mealType,
                                      userId: widget.userId,
                                      docId: doc.id,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  Navigator.pop(context, true);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}