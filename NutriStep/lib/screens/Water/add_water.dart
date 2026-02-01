import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddWaterPage extends StatefulWidget {
  final String userId;

  const AddWaterPage({super.key, required this.userId});

  @override
  State<AddWaterPage> createState() => _AddWaterPageState();
}

class _AddWaterPageState extends State<AddWaterPage> with SingleTickerProviderStateMixin {
  static const double _dailyGoal = 2000; // 2000mL daily goal for tank display

  int totalWater = 0;
  List<Map<String, dynamic>> entries = [];
  late AnimationController _controller;
  late Animation<double> _fillAnimation;
  double _previousFillPercent = 0.0;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateFillAnimation() {
    final newPercent = (_dailyGoal > 0) ? (min(totalWater, _dailyGoal) / _dailyGoal) : 0.0;
    _fillAnimation = Tween<double>(
      begin: _previousFillPercent,
      end: newPercent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _previousFillPercent = newPercent;
    _controller
      ..reset()
      ..forward();
  }

  void addWater(int ml) {
    setState(() {
      totalWater += ml;
      entries.add({
        'amount_ml': ml,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _updateFillAnimation();
    });
  }

  Future<void> saveWaterLog() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('logs')
        .doc(today);

    final docSnapshot = await docRef.get();

    int previousTotal = 0;
    List<dynamic> existingEntries = [];

    if (docSnapshot.exists && docSnapshot.data()?['water'] != null) {
      final data = docSnapshot.data()!;
      previousTotal = (data['water']['total_water_ml'] ?? 0);
      existingEntries = List.from(data['water']['entries'] ?? []);
    }

    final updatedTotal = previousTotal + totalWater;
    final updatedEntries = [...existingEntries, ...entries];

    await docRef.set({
      'water': {
        'total_water_ml': updatedTotal,
        'entries': updatedEntries,
      }
    }, SetOptions(merge: true));

    Navigator.pop(context, true);
  }

  void showCustomInputDialog() {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Custom Amount",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: "Enter ml amount",
            labelStyle: theme.inputDecorationTheme.labelStyle,
            hintText: "e.g., 300",
            hintStyle: theme.inputDecorationTheme.hintStyle,
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor,
            border: theme.inputDecorationTheme.border,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
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
            onPressed: () {
              final ml = int.tryParse(controller.text.trim());
              if (ml != null && ml > 0) {
                addWater(ml);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please enter a valid amount",
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

  Widget buildWaterButton(String label, int ml) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isButtonPressed = true),
      onTapUp: (_) => setState(() => _isButtonPressed = false),
      onTapCancel: () => setState(() => _isButtonPressed = false),
      onTap: () => addWater(ml),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isButtonPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.local_drink, size: 28, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorScheme.primary, colorScheme.secondary],
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            "Log Water",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.local_drink, size: 36, color: colorScheme.primary),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Intake",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$totalWater ml",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: AnimatedBuilder(
                  animation: _fillAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _WaterTankPainter(_fillAnimation.value, colorScheme),
                      child: SizedBox(
                        width: 120,
                        height: 240,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    buildWaterButton("250 ml", 250),
                    const SizedBox(width: 16),
                    buildWaterButton("500 ml", 500),
                    const SizedBox(width: 16),
                    buildWaterButton("1000 ml", 1000),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isButtonPressed = true),
                      onTapUp: (_) => setState(() => _isButtonPressed = false),
                      onTapCancel: () => setState(() => _isButtonPressed = false),
                      onTap: showCustomInputDialog,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()..scale(_isButtonPressed ? 0.95 : 1.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface,
                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.edit, size: 32, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              "Custom",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTapDown: (_) => setState(() => _isButtonPressed = true),
                onTapUp: (_) => setState(() => _isButtonPressed = false),
                onTapCancel: () => setState(() => _isButtonPressed = false),
                onTap: saveWaterLog,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.identity()..scale(_isButtonPressed ? 0.95 : 1.0),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, color: colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          "Save",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterTankPainter extends CustomPainter {
  final double fillPercent;
  final ColorScheme colorScheme;

  _WaterTankPainter(this.fillPercent, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint borderPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Paint fillPaint = Paint()
      ..color = Colors.blue.shade300.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final RRect tankRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(tankRect, borderPaint);

    final double fillHeight = size.height * fillPercent;
    final Rect fillRect = Rect.fromLTWH(
      0,
      size.height - fillHeight,
      size.width,
      fillHeight,
    );
    final RRect fillRRect = RRect.fromRectAndRadius(
      fillRect,
      const Radius.circular(12),
    );
    canvas.clipRRect(tankRect);
    canvas.drawRRect(fillRRect, fillPaint);

    if (fillHeight > 12) {
      final double waveY = size.height - fillHeight + 6;
      final Paint wavePaint = Paint()
        ..color = colorScheme.onSurface.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final Path wavePath = Path();
      final double amplitude = 4;
      final double waveLength = size.width / 3;
      wavePath.moveTo(0, waveY);
      for (double x = 0; x <= size.width; x += 1) {
        final y = waveY +
            sin((x / size.width) * 2 * pi) * amplitude * (fillPercent.clamp(0.0, 1.0));
        wavePath.lineTo(x, y);
      }
      canvas.drawPath(wavePath, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterTankPainter oldDelegate) {
    return oldDelegate.fillPercent != fillPercent || oldDelegate.colorScheme != colorScheme;
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}