import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/screens/Exercise/Strength/my_strength.dart';
import 'strength_detail.dart';

class AddStrengthPage extends StatefulWidget {
  final String userId;
  const AddStrengthPage({super.key, required this.userId});

  @override
  State<AddStrengthPage> createState() => _AddStrengthPageState();
}

class _AddStrengthPageState extends State<AddStrengthPage> with SingleTickerProviderStateMixin {
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
    setState(() => loading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('strength')
        .limit(12)
        .get();

    setState(() {
      suggestionExercises = snapshot.docs
          .map((e) => e.data()..['docId'] = e.id)
          .toList()
          .cast<Map<String, dynamic>>();
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
        .collection('strength')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      historyExercises = snapshot.docs
          .map((e) => e.data()..['docId'] = e.id)
          .toList()
          .cast<Map<String, dynamic>>();
    });
  }

  void handleSearch(String query) async {
    setState(() => searchQuery = query);

    if (query.isEmpty) {
      await fetchSuggestions();
      return;
    }

    final result = await FirebaseFirestore.instance
        .collection('strength')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(12)
        .get();

    setState(() {
      suggestionExercises = result.docs
          .map((e) => e.data()..['docId'] = e.id)
          .toList()
          .cast<Map<String, dynamic>>();
    });
  }

  Widget buildExerciseTile(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = data['name'] ?? '';
    final weight = data['weight_per_repetition'] ?? 0;
    final reps = data['repetitions_per_set'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              "Weight: ${weight}kg  ·  Reps: $reps",
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
                  builder: (_) => StrengthDetailPage(
                    exerciseData: data,
                    userId: widget.userId,
                    docId: data['docId'],
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Recently Added",
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ...historyExercises.map(buildExerciseTile),
      ],
    );
  }

  Widget buildSuggestionsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (historyExercises.isNotEmpty) const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            "Suggestions",
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ...suggestionExercises.map(buildExerciseTile),
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
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            "Strength Exercises",
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
            Tab(text: 'All Exercises'),
            Tab(text: 'My Exercises'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                MyStrengthExercisesPage(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}