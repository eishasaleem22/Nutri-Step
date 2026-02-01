import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FoodDetailPage extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final String mealType;
  final String userId;
  final String? docId;

  const FoodDetailPage({
    super.key,
    required this.foodData,
    required this.mealType,
    required this.userId,
    this.docId,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late TextEditingController servingsController;

  @override
  void initState() {
    super.initState();
    final initial = widget.foodData['servings']?.toString() ?? '1';
    servingsController = TextEditingController(text: initial);
  }

  double get servings => double.tryParse(servingsController.text) ?? 1;
  double get calories => (widget.foodData['calories'] as num?)?.toDouble() ?? 0;
  double get carbs => ((widget.foodData['nutrients']?['carbohydrates'] ??
      widget.foodData['carbohydrates'] ??
      widget.foodData['carbs'] ??
      0) as num)
      .toDouble() *
      servings;
  double get fat => ((widget.foodData['nutrients']?['fat'] ??
      widget.foodData['fat'] ??
      0) as num)
      .toDouble() *
      servings;
  double get protein => ((widget.foodData['nutrients']?['protein'] ??
      widget.foodData['protein'] ??
      0) as num)
      .toDouble() *
      servings;
  double get totalCalories => calories * servings;

  Future<void> addToMealLog() async {
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (servings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Servings must be at least 1",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final foodEntry = {
      'name': widget.foodData['name'],
      'serving_size': widget.foodData['serving_size'],
      'calories': calories,
      'servings': servings,
      'total_calories': totalCalories,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('logs')
        .doc(today)
        .collection(widget.mealType);

    if (widget.docId != null) {
      await ref.doc(widget.docId).update(foodEntry);
    } else {
      await ref.add(foodEntry);
    }

    Navigator.pop(context, true);
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
    final foodName = widget.foodData['name'] ?? '';
    final servingSize = widget.foodData['serving_size'] ?? '-';

    final double carbCal = carbs * 4;
    final double fatCal = fat * 9;
    final double proteinCal = protein * 4;
    final double macroTotal = carbCal + fatCal + proteinCal;

    final double carbPercent = macroTotal > 0 ? (carbCal / macroTotal) : 0;
    final double fatPercent = macroTotal > 0 ? (fatCal / macroTotal) : 0;
    final double proteinPercent = macroTotal > 0 ? (proteinCal / macroTotal) : 0;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            widget.docId != null ? "Edit Food" : "Add Food",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
        actions: [
          IconButton(
            icon: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.check, color: colorScheme.onPrimary, size: 20),
            ),
            onPressed: addToMealLog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  foodName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _infoRow("Meal", widget.mealType.capitalize()),
                    const SizedBox(height: 12),
                    _servingInputRow("Servings"),
                    const SizedBox(height: 12),
                    _infoRow("Serving Size", servingSize),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Card(
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CustomPaint(
                        painter: _MacroCirclePainter(
                          carbs: carbs,
                          fat: fat,
                          protein: protein,
                          total: totalCalories,
                          colorScheme: colorScheme,
                        ),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  totalCalories.toStringAsFixed(0),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Cal",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _macroText(carbs, "Carbs", Colors.blue, carbPercent, Icons.grain),
                          _macroText(fat, "Fat", colorScheme.secondary, fatPercent, Icons.local_pizza),
                          _macroText(protein, "Protein", colorScheme.primary, proteinPercent, Icons.fitness_center),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _servingInputRow(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: servingsController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              filled: theme.inputDecorationTheme.filled,
              fillColor: theme.inputDecorationTheme.fillColor,
              border: theme.inputDecorationTheme.border,
              enabledBorder: theme.inputDecorationTheme.enabledBorder,
              focusedBorder: theme.inputDecorationTheme.focusedBorder,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _macroText(double grams, String label, Color color, double percent, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              "${(percent * 100).toStringAsFixed(0)}%",
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "${grams.toStringAsFixed(2)}g",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _MacroCirclePainter extends CustomPainter {
  final double carbs;
  final double fat;
  final double protein;
  final double total;
  final ColorScheme colorScheme;

  _MacroCirclePainter({
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.total,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final radius = (size.width / 2) - (strokeWidth / 2);
    final center = size.center(Offset.zero);

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = colorScheme.onSurface.withOpacity(0.2);
    canvas.drawCircle(center, radius, backgroundPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngleDeg = -90.0;

    final double carbCal = carbs * 4;
    final double fatCal = fat * 9;
    final double proteinCal = protein * 4;
    final double macroSum = carbCal + fatCal + proteinCal;

    void drawSegment(double valueCal, Color color) {
      if (valueCal <= 0 || macroSum == 0) return;
      final sweepDeg = 360 * (valueCal / macroSum);
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _degToRad(startAngleDeg),
        _degToRad(sweepDeg),
        false,
        paint,
      );
      startAngleDeg += sweepDeg;
    }

    drawSegment(carbCal, Colors.blue);
    drawSegment(fatCal, colorScheme.secondary);
    drawSegment(proteinCal, colorScheme.primary);
  }

  double _degToRad(double deg) => deg * (3.1415926535897932 / 180);

  @override
  bool shouldRepaint(_MacroCirclePainter oldDelegate) =>
      carbs != oldDelegate.carbs ||
          fat != oldDelegate.fat ||
          protein != oldDelegate.protein ||
          total != oldDelegate.total ||
          colorScheme != oldDelegate.colorScheme;
}

extension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}