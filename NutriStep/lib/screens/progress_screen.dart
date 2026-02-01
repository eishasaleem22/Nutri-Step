import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _goal = 1420;
  List<_DayData> _last7Days = [];
  double _todayCarbs = 0, _todayFat = 0, _todayProtein = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 1) Load the true goal
    _loadUserGoal()
    // 2) Once that's done, fetch progress
        .whenComplete(() => _fetchAllProgress());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAllProgress();
    }
  }

  Future<void> _loadUserGoal() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1) Fetch the user profile doc
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    // 2) Read the stored dailyCalorieTarget field (you wrote this in profile)
    //    or compute it here exactly as you do in Dashboard
    final stored = doc.data()?['dailyCalorieTarget'];
    if (stored != null) {
      setState(() {
        _goal = (stored as num).toDouble();
      });
    }
  }

  Future<void> _fetchAllProgress() async {
    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userId = user.uid;
    final now = DateTime.now();
    List<DateTime> days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: i)))
      ..sort((a, b) => a.compareTo(b));

    List<_DayData> temp = [];
    double carbsSum = 0, fatSum = 0, proteinSum = 0;

    for (DateTime day in days) {
      final dayKey = DateFormat('yyyy-MM-dd').format(day);
      double foodTotal = 0;
      double carbsTotal = 0, fatTotal = 0, proteinTotal = 0;

      for (String meal in ['breakfast', 'lunch', 'dinner', 'others']) {
        final snap = await _firestore
            .collection('users')
            .doc(userId)
            .collection('logs')
            .doc(dayKey)
            .collection(meal)
            .get();

        for (var doc in snap.docs) {
          final data = doc.data();
          final tCal = (data['total_calories'] as num?)?.toDouble() ?? 0;
          foodTotal += tCal;
          carbsTotal += ((data['carbs'] as num?)?.toDouble() ?? 0);
          fatTotal += ((data['fat'] as num?)?.toDouble() ?? 0);
          proteinTotal += ((data['protein'] as num?)?.toDouble() ?? 0);
        }
      }

      double exerciseTotal = 0;
      final cardioSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(dayKey)
          .collection('cardio')
          .get();
      for (var doc in cardioSnap.docs) {
        exerciseTotal += ((doc.data()['calories_burned'] as num?)?.toDouble() ?? 0);
      }

      final strengthSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(dayKey)
          .collection('strength')
          .get();
      for (var doc in strengthSnap.docs) {
        exerciseTotal += ((doc.data()['calories_burned'] as num?)?.toDouble() ?? 0);
      }

      double remaining = _goal - foodTotal + exerciseTotal;

      temp.add(_DayData(
        dateLabel: DateFormat('dd MMM').format(day),
        foodCalories: foodTotal,
        exerciseCalories: exerciseTotal,
        remainingCalories: remaining,
        carbs: carbsTotal,
        fat: fatTotal,
        protein: proteinTotal,
      ));

      if (dayKey == DateFormat('yyyy-MM-dd').format(now)) {
        carbsSum = carbsTotal;
        fatSum = fatTotal;
        proteinSum = proteinTotal;
      }
    }

    setState(() {
      _last7Days = temp;
      _todayCarbs = carbsSum;
      _todayFat = fatSum;
      _todayProtein = proteinSum;
      _isLoading = false;
    });
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            "Your Progress",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 56, // Added padding for bottom nav bar
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: Text(
                "Weekly Calorie Trend",
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Track your calorie intake and expenditure",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.7,
                  child: LineChart(_buildLineChartData()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem("Food", colorScheme.primary),
                const SizedBox(width: 16),
                _legendItem("Exercise", colorScheme.secondary),
                const SizedBox(width: 16),
                _legendItem("Remaining", Colors.blue), // No direct theme color match; using blue as fallback
              ],
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: Text(
                "Today’s Macronutrients",
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Breakdown of your daily macros",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: BarChart(_buildBarChartData()),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildMacronutrientDetails(),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData() {
    final colorScheme = Theme.of(context).colorScheme;
    final spotsFood = <FlSpot>[];
    final spotsExercise = <FlSpot>[];
    final spotsRemaining = <FlSpot>[];

    for (int i = 0; i < _last7Days.length; i++) {
      final day = _last7Days[i];
      spotsFood.add(FlSpot(i.toDouble(), day.foodCalories));
      spotsExercise.add(FlSpot(i.toDouble(), day.exerciseCalories));
      spotsRemaining.add(FlSpot(i.toDouble(), day.remainingCalories));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _computeHorizontalInterval(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.onBackground.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index < 0 || index >= _last7Days.length) return const Text('');
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _last7Days[index].dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onBackground,
                  ),
                ),
              );
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onBackground,
              ),
            ),
            interval: _computeHorizontalInterval(),
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: colorScheme.onBackground.withOpacity(0.2)),
      ),
      minX: 0,
      maxX: (_last7Days.length - 1).toDouble(),
      minY: 0,
      maxY: _computeMaxY(),
      lineBarsData: [
        LineChartBarData(
          spots: spotsFood,
          isCurved: true,
          color: colorScheme.primary,
          barWidth: 2,
          dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3, color: colorScheme.primary)),
        ),
        LineChartBarData(
          spots: spotsExercise,
          isCurved: true,
          color: colorScheme.secondary,
          barWidth: 2,
          dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3, color: colorScheme.secondary)),
        ),
        LineChartBarData(
          spots: spotsRemaining,
          isCurved: true,
          color: Colors.blue, // No direct theme color match; using blue as fallback
          barWidth: 2,
          dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3, color: Colors.blue)),
        ),
      ],
    );
  }

  double _computeHorizontalInterval() {
    double maxVal = 0;
    for (var d in _last7Days) {
      maxVal = [maxVal, d.foodCalories, d.exerciseCalories, d.remainingCalories].reduce((a, b) => a > b ? a : b);
    }
    if (maxVal <= 200) return 50;
    if (maxVal <= 500) return 100;
    if (maxVal <= 1000) return 200;
    return 500;
  }

  double _computeMaxY() {
    double maxVal = 0;
    for (var d in _last7Days) {
      maxVal = [maxVal, d.foodCalories, d.exerciseCalories, d.remainingCalories].reduce((a, b) => a > b ? a : b);
    }
    return (maxVal * 1.2).ceilToDouble();
  }

  BarChartData _buildBarChartData() {
    final colorScheme = Theme.of(context).colorScheme;
    final totalMacroCalories = _todayCarbs * 4 + _todayFat * 9 + _todayProtein * 4;
    final carbPct = totalMacroCalories > 0 ? (_todayCarbs * 4) / totalMacroCalories : 0.0;
    final fatPct = totalMacroCalories > 0 ? (_todayFat * 9) / totalMacroCalories : 0.0;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0:
                  return _bottomTitle('Carbs', colorScheme.primary);
                case 1:
                  return _bottomTitle('Fat', colorScheme.secondary);
                case 2:
                  return _bottomTitle('Protein', Colors.blue); // No direct theme color match
                default:
                  return const SizedBox();
              }
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onBackground,
              ),
            ),
            interval: _computeMacroInterval(),
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(
            toY: _todayCarbs,
            width: 16,
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          )
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(
            toY: _todayFat,
            width: 16,
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(4),
          )
        ]),
        BarChartGroupData(x: 2, barRods: [
          BarChartRodData(
            toY: _todayProtein,
            width: 16,
            color: Colors.blue, // No direct theme color match
            borderRadius: BorderRadius.circular(4),
          )
        ]),
      ],
      maxY: _computeMaxMacroY(),
    );
  }

  Widget _bottomTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
        ),
      ),
    );
  }

  double _computeMaxMacroY() {
    final maxVal = [_todayCarbs, _todayFat, _todayProtein].reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.2).ceilToDouble();
  }

  double _computeMacroInterval() {
    final maxVal = [_todayCarbs, _todayFat, _todayProtein].reduce((a, b) => a > b ? a : b);
    if (maxVal <= 5) return 1;
    if (maxVal <= 20) return 5;
    return 10;
  }

  Widget _buildMacronutrientDetails() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today’s Totals",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _macroInfoBox('Carbs', _todayCarbs, colorScheme.primary),
            const SizedBox(width: 12),
            _macroInfoBox('Fat', _todayFat, colorScheme.secondary),
            const SizedBox(width: 12),
            _macroInfoBox('Protein', _todayProtein, Colors.blue), // No direct theme color match
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _macroInfoBox(String label, double grams, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                "${grams.toStringAsFixed(1)}g",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayData {
  final String dateLabel;
  final double foodCalories;
  final double exerciseCalories;
  final double remainingCalories;
  final double carbs;
  final double fat;
  final double protein;

  _DayData({
    required this.dateLabel,
    required this.foodCalories,
    required this.exerciseCalories,
    required this.remainingCalories,
    required this.carbs,
    required this.fat,
    required this.protein,
  });
}