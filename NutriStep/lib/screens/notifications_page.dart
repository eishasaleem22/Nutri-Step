import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _mealEnabled = false;
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  bool _waterEnabled = false;
  List<TimeOfDay> _waterTimes = [];
  bool _exerciseEnabled = false;
  TimeOfDay _exerciseTime = const TimeOfDay(hour: 18, minute: 0);
  bool _goalAlertEnabled = false;
  bool _inactivityAlertEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _mealEnabled = prefs.getBool('meal_reminder_enabled') ?? false;
      _breakfastTime = TimeOfDay(
        hour: prefs.getInt('breakfast_hour') ?? 8,
        minute: prefs.getInt('breakfast_minute') ?? 0,
      );
      _lunchTime = TimeOfDay(
        hour: prefs.getInt('lunch_hour') ?? 13,
        minute: prefs.getInt('lunch_minute') ?? 0,
      );
      _dinnerTime = TimeOfDay(
        hour: prefs.getInt('dinner_hour') ?? 19,
        minute: prefs.getInt('dinner_minute') ?? 0,
      );
      _waterEnabled = prefs.getBool('water_enabled') ?? false;
      final waterList = prefs.getStringList('water_times') ?? [];
      _waterTimes = waterList.map((s) {
        final parts = s.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
      _exerciseEnabled = prefs.getBool('exercise_enabled') ?? false;
      _exerciseTime = TimeOfDay(
        hour: prefs.getInt('exercise_hour') ?? 18,
        minute: prefs.getInt('exercise_minute') ?? 0,
      );
      _goalAlertEnabled = prefs.getBool('goal_alert_enabled') ?? false;
      _inactivityAlertEnabled = prefs.getBool('inactivity_alert_enabled') ?? false;
    });

    if (_mealEnabled) _rescheduleMeal();
    if (_waterEnabled) _rescheduleAllWater();
    if (_exerciseEnabled) _rescheduleExercise();
    if (_goalAlertEnabled) _rescheduleGoal();
    if (_inactivityAlertEnabled) _rescheduleInactivity();
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(t.hour)}:${twoDigits(t.minute)}';
  }

  Future<void> _saveMealToggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('meal_reminder_enabled', enabled);
    setState(() => _mealEnabled = enabled);

    if (enabled) {
      prefs.setInt('breakfast_hour', _breakfastTime.hour);
      prefs.setInt('breakfast_minute', _breakfastTime.minute);
      prefs.setInt('lunch_hour', _lunchTime.hour);
      prefs.setInt('lunch_minute', _lunchTime.minute);
      prefs.setInt('dinner_hour', _dinnerTime.hour);
      prefs.setInt('dinner_minute', _dinnerTime.minute);
      await NotificationService().cancelChannelNotifications(channelId: NotificationService.mealChannelId);
      _scheduleBreakfast();
      _scheduleLunch();
      _scheduleDinner();
    } else {
      await NotificationService().cancelChannelNotifications(channelId: NotificationService.mealChannelId);
    }
  }

  Future<void> _pickMealTime(TimeOfDay initial, ValueChanged<TimeOfDay> onPicked) async {
    final theme = Theme.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.secondary),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  void _scheduleBreakfast() {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _breakfastTime.hour, _breakfastTime.minute);
    NotificationService().scheduleNotification(
      id: NotificationService.breakfastId,
      channelId: NotificationService.mealChannelId,
      channelName: 'Meal Reminders',
      title: 'Meal Reminder',
      body: 'Time for breakfast!',
      scheduledDateTime: dt,
      repeatDaily: true,
    );
  }

  void _scheduleLunch() {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _lunchTime.hour, _lunchTime.minute);
    NotificationService().scheduleNotification(
      id: NotificationService.lunchId,
      channelId: NotificationService.mealChannelId,
      channelName: 'Meal Reminders',
      title: 'Meal Reminder',
      body: 'Time for lunch!',
      scheduledDateTime: dt,
      repeatDaily: true,
    );
  }

  void _scheduleDinner() {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _dinnerTime.hour, _dinnerTime.minute);
    NotificationService().scheduleNotification(
      id: NotificationService.dinnerId,
      channelId: NotificationService.mealChannelId,
      channelName: 'Meal Reminders',
      title: 'Meal Reminder',
      body: 'Time for dinner!',
      scheduledDateTime: dt,
      repeatDaily: true,
    );
  }

  Future<void> _pickBreakfastTime() async {
    await _pickMealTime(_breakfastTime, (picked) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('breakfast_hour', picked.hour);
      prefs.setInt('breakfast_minute', picked.minute);
      setState(() => _breakfastTime = picked);
      if (_mealEnabled) {
        await NotificationService().cancelChannelNotifications(channelId: NotificationService.mealChannelId);
        _scheduleBreakfast();
        _scheduleLunch();
        _scheduleDinner();
      }
    });
  }

  Future<void> _pickLunchTime() async {
    await _pickMealTime(_lunchTime, (picked) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('lunch_hour', picked.hour);
      prefs.setInt('lunch_minute', picked.minute);
      setState(() => _lunchTime = picked);
      if (_mealEnabled) {
        await NotificationService().cancelChannelNotifications(channelId: NotificationService.mealChannelId);
        _scheduleBreakfast();
        _scheduleLunch();
        _scheduleDinner();
      }
    });
  }

  Future<void> _pickDinnerTime() async {
    await _pickMealTime(_dinnerTime, (picked) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('dinner_hour', picked.hour);
      prefs.setInt('dinner_minute', picked.minute);
      setState(() => _dinnerTime = picked);
      if (_mealEnabled) {
        await NotificationService().cancelChannelNotifications(channelId: NotificationService.mealChannelId);
        _scheduleBreakfast();
        _scheduleLunch();
        _scheduleDinner();
      }
    });
  }

  Future<void> _rescheduleMeal() async {
    await NotificationService().cancelChannelNotifications(channelId: NotificationService.mealChannelId);
    _scheduleBreakfast();
    _scheduleLunch();
    _scheduleDinner();
  }

  Future<void> _saveWaterToggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_enabled', enabled);
    setState(() => _waterEnabled = enabled);

    if (!enabled) {
      for (var t in _waterTimes) {
        final id = _idForTime(t);
        await NotificationService().cancelNotification(id);
      }
    } else {
      await _rescheduleAllWater();
    }
  }

  Future<void> _addWaterTime() async {
    DateTime now = DateTime.now();
    final defaultTime = _waterTimes.isNotEmpty
        ? _waterTimes.last
        : const TimeOfDay(hour: 9, minute: 0);
    final initialDateTime = DateTime(
      now.year, now.month, now.day, defaultTime.hour, defaultTime.minute,
    );

    await DatePicker.showTimePicker(
      context,
      showTitleActions: true,
      currentTime: initialDateTime,
      onChanged: (_) {},
      onConfirm: (date) async {
        final picked = TimeOfDay(hour: date.hour, minute: date.minute);
        bool alreadyExists = _waterTimes.any((t) =>
        t.hour == picked.hour && t.minute == picked.minute
        );
        if (alreadyExists) return;

        final prefs = await SharedPreferences.getInstance();
        _waterTimes.add(picked);
        final serialized = _waterTimes.map((t) => _formatTimeOfDay(t)).toList();
        await prefs.setStringList('water_times', serialized);

        setState(() {});
        if (_waterEnabled) {
          _scheduleSingleWater(picked);
        }
      },
    );
  }

  void _scheduleSingleWater(TimeOfDay t) {
    DateTime now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final id = _idForTime(t);
    NotificationService().scheduleNotification(
      id: id,
      channelId: NotificationService.waterChannelId,
      channelName: 'Water Intake Reminders',
      title: 'Water Reminder',
      body: 'Time to drink water!',
      scheduledDateTime: scheduled,
      repeatDaily: true,
    );
  }

  Future<void> _removeWaterTime(int index) async {
    final t = _waterTimes[index];
    final id = _idForTime(t);
    await NotificationService().cancelNotification(id);

    final prefs = await SharedPreferences.getInstance();
    _waterTimes.removeAt(index);
    final serialized = _waterTimes.map((t) => _formatTimeOfDay(t)).toList();
    await prefs.setStringList('water_times', serialized);

    setState(() {});
  }

  Future<void> _rescheduleAllWater() async {
    for (var t in _waterTimes) {
      final id = _idForTime(t);
      await NotificationService().cancelNotification(id);
    }
    for (var t in _waterTimes) {
      _scheduleSingleWater(t);
    }
  }

  TimeOfDay _parseTimeOfDay(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  int _idForTime(TimeOfDay t) => t.hour * 100 + t.minute;

  Future<void> _saveExerciseToggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('exercise_enabled', enabled);
    setState(() => _exerciseEnabled = enabled);

    if (enabled) {
      prefs.setInt('exercise_hour', _exerciseTime.hour);
      prefs.setInt('exercise_minute', _exerciseTime.minute);
      await NotificationService().cancelChannelNotifications(channelId: NotificationService.exerciseChannelId);
      _scheduleExercise();
    } else {
      await NotificationService().cancelChannelNotifications(channelId: NotificationService.exerciseChannelId);
    }
  }

  Future<void> _pickExerciseTime() async {
    await _pickMealTime(_exerciseTime, (picked) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('exercise_hour', picked.hour);
      prefs.setInt('exercise_minute', picked.minute);
      setState(() => _exerciseTime = picked);
      if (_exerciseEnabled) {
        await NotificationService().cancelChannelNotifications(channelId: NotificationService.exerciseChannelId);
        _scheduleExercise();
      }
    });
  }

  void _scheduleExercise() {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _exerciseTime.hour, _exerciseTime.minute);
    NotificationService().scheduleNotification(
      id: NotificationService.exerciseId,
      channelId: NotificationService.exerciseChannelId,
      channelName: 'Exercise Prompts',
      title: 'Exercise Reminder',
      body: 'Time for your daily workout!',
      scheduledDateTime: dt,
      repeatDaily: true,
    );
  }

  Future<void> _rescheduleExercise() async {
    await NotificationService().cancelChannelNotifications(channelId: NotificationService.exerciseChannelId);
    _scheduleExercise();
  }

  Future<void> _saveGoalToggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('goal_alert_enabled', enabled);
    setState(() => _goalAlertEnabled = enabled);

    if (!enabled) {
      await NotificationService().cancelChannelNotifications(channelId: NotificationService.goalChannelId);
    } else {
      _rescheduleGoal();
    }
  }

  void _scheduleGoal() {
    final now = DateTime.now();
    final hour = DateTime.now().hour;
    final minute = DateTime.now().minute;
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    NotificationService().scheduleNotification(
      id: NotificationService.goalId,
      channelId: NotificationService.goalChannelId,
      channelName: 'Goal Achievement Alerts',
      title: 'Goal Check',
      body: 'Check if you’ve reached 1420 calories!',
      scheduledDateTime: dt,
      repeatDaily: true,
    );
  }

  Future<void> _rescheduleGoal() async {
    await NotificationService().cancelChannelNotifications(channelId: NotificationService.goalChannelId);
    _scheduleGoal();
  }

  Future<void> _saveInactivityToggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('inactivity_alert_enabled', enabled);
    setState(() => _inactivityAlertEnabled = enabled);

    if (!enabled) {
      await NotificationService().cancelChannelNotifications(channelId: NotificationService.inactivityChannelId);
    } else {
      _rescheduleInactivity();
    }
  }

  void _scheduleInactivity() {
    final now = DateTime.now();
    final hour = DateTime.now().hour;
    final minute = DateTime.now().minute;
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    NotificationService().scheduleNotification(
      id: NotificationService.inactivityId,
      channelId: NotificationService.inactivityChannelId,
      channelName: 'Inactivity Alerts',
      title: 'Inactivity Alert',
      body: 'You’ve been inactive for 48h!',
      scheduledDateTime: dt,
      repeatDaily: true,
    );
  }

  Future<void> _rescheduleInactivity() async {
    await NotificationService().cancelChannelNotifications(channelId: NotificationService.inactivityChannelId);
    _scheduleInactivity();
  }

  Future<void> _testNotification() async {
    await NotificationService().showNotification(
      id: 0,
      channelId: NotificationService.mealChannelId,
      channelName: 'Meal Reminders',
      title: 'Test Notification',
      body: 'This is a test notification to verify the system!',
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
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            "Notifications",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        iconTheme: theme.appBarTheme.iconTheme,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  "Manage Notifications",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: colorScheme.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Customize your notification settings",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              _buildToggleTile(
                title: 'Meal Reminders',
                subtitle:
                'Breakfast: ${_breakfastTime.format(context)}, Lunch: ${_lunchTime.format(context)}, Dinner: ${_dinnerTime.format(context)}',
                value: _mealEnabled,
                onToggle: _saveMealToggle,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: colorScheme.surface,
                      title: Text('Select Meal Times',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                          )),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text('Breakfast',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                )),
                            trailing: Text(_breakfastTime.format(context),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                )),
                            onTap: () {
                              Navigator.pop(context);
                              _pickBreakfastTime();
                            },
                          ),
                          ListTile(
                            title: Text('Lunch',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                )),
                            trailing: Text(_lunchTime.format(context),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                )),
                            onTap: () {
                              Navigator.pop(context);
                              _pickLunchTime();
                            },
                          ),
                          ListTile(
                            title: Text('Dinner',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                )),
                            trailing: Text(_dinnerTime.format(context),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                )),
                            onTap: () {
                              Navigator.pop(context);
                              _pickDinnerTime();
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.secondary,
                              )),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icons.restaurant,
              ),
              const SizedBox(height: 16),
              _buildToggleTile(
                title: 'Water Intake Reminders',
                subtitle: _waterEnabled
                    ? 'You have ${_waterTimes.length} reminder(s)'
                    : 'Disabled',
                value: _waterEnabled,
                onToggle: _saveWaterToggle,
                onTap: () {
                  if (!_waterEnabled) return;
                  _addWaterTime();
                },
                icon: Icons.local_drink,
              ),
              if (_waterEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: _waterTimes.asMap().entries.map((entry) {
                      int idx = entry.key;
                      TimeOfDay t = entry.value;
                      return Card(
                        color: colorScheme.surface,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(
                            'Reminder at ${t.format(context)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            onPressed: () => _removeWaterTime(idx),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              _buildToggleTile(
                title: 'Exercise Prompts',
                subtitle: 'Every day at ${_exerciseTime.format(context)}',
                value: _exerciseEnabled,
                onToggle: _saveExerciseToggle,
                onTap: () {
                  if (!_exerciseEnabled) return;
                  _pickExerciseTime();
                },
                icon: Icons.fitness_center,
              ),
              const SizedBox(height: 16),
              _buildToggleTile(
                title: 'Goal Achievement Alerts',
                subtitle: _goalAlertEnabled ? 'Enabled' : 'Disabled',
                value: _goalAlertEnabled,
                onToggle: _saveGoalToggle,
                onTap: null,
                icon: Icons.star,
              ),
              const SizedBox(height: 16),
              _buildToggleTile(
                title: 'Inactivity/Streak Alerts',
                subtitle: _inactivityAlertEnabled ? 'Enabled' : 'Disabled',
                value: _inactivityAlertEnabled,
                onToggle: _saveInactivityToggle,
                onTap: null,
                icon: Icons.warning,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onToggle,
    VoidCallback? onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor: colorScheme.primary,
          inactiveThumbColor: colorScheme.onSurface.withOpacity(0.6),
          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
          onChanged: onToggle,
        ),
        onTap: onTap,
      ),
    );
  }
}