import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cardio_detail.dart';
import 'my_cardio.dart';

class AddCardioPage extends StatefulWidget {
  final String userId;
  const AddCardioPage({super.key, required this.userId});

  @override
  State<AddCardioPage> createState() => _AddCardioPageState();
}

class _AddCardioPageState extends State<AddCardioPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  List<Map<String, dynamic>> suggestionExercises = [];
  List<Map<String, dynamic>> historyExercises = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchSuggestions();
    fetchHistory();
  }

  Future<void> fetchSuggestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('cardio')
        .orderBy('name')
        .limit(12)
        .get();
    setState(() {
      suggestionExercises = snapshot.docs.map((e) => e.data()).toList().cast<Map<String, dynamic>>();
      loading = false;
    });
  }

  Future<void> fetchHistory() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('logs')
        .doc(today)
        .collection('cardio')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      historyExercises = snapshot.docs.map((e) => e.data()).toList().cast<Map<String, dynamic>>();
    });
  }

  void handleSearch(String query) async {
    setState(() => searchQuery = query);
    if (query.isEmpty) {
      fetchSuggestions();
      return;
    }
    final result = await FirebaseFirestore.instance
        .collection('cardio')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(12)
        .get();

    setState(() {
      suggestionExercises = result.docs.map((e) => e.data()).toList().cast<Map<String, dynamic>>();
    });
  }

  Widget buildExerciseTile(Map<String, dynamic> exercise) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = exercise['name'] ?? '';
    final calPerMin = (exercise['calories_burned_per_min'] ?? 0).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "Calories: $calPerMin / min",
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
                  builder: (_) => CardioDetailPage(
                    exerciseData: exercise,
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
      ),
    );
  }

  Widget buildHistorySection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (historyExercises.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
          child: Text(
            "Recently Added",
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ...historyExercises.map(buildExerciseTile).toList(),
      ],
    );
  }

  Widget buildSuggestionsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (historyExercises.isNotEmpty)
          const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
          child: Text(
            "Suggestions",
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ...suggestionExercises.map(buildExerciseTile).toList(),
      ],
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
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            "Cardio Exercises",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All Exercises'),
            Tab(text: 'My Exercises'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: handleSearch,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "Search for an exercise",
                hintStyle: theme.inputDecorationTheme.hintStyle,
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                filled: theme.inputDecorationTheme.filled,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                loading
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: () async {
                    await fetchSuggestions();
                    await fetchHistory();
                  },
                  color: colorScheme.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      buildHistorySection(),
                      buildSuggestionsSection(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                MyCardioExercisesPage(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}