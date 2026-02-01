// lib/main.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/services/push_notification_service.dart';
import 'package:flutter_projects/utils/theme.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



import 'services/notification_service.dart';
import 'screens/notifications_page.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/Food/add_food_page.dart';
import 'screens/Water/add_water.dart';
import 'screens/Exercise/Cardio/add_cardio.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
  // Tell FCM which function to call in background
  // Initialize FCM
  await PushNotificationService().init();
  // 1) On Android 13+ request POST_NOTIFICATIONS permission
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      debugPrint('Notification permission not granted');
    }
  }

  // 2) Initialize local notifications (create channels, etc.)
  await NotificationService().initNotification();










  // 4) Now read prefs & re-schedule only toggled-ON reminders
  final prefs = await SharedPreferences.getInstance();

  // — Meal Reminders —
  final mealEnabled = prefs.getBool('meal_reminder_enabled') ?? false;
  if (mealEnabled) {
    final bH = prefs.getInt('breakfast_hour') ?? 8;
    final bM = prefs.getInt('breakfast_minute') ?? 0;
    final lH = prefs.getInt('lunch_hour') ?? 13;
    final lM = prefs.getInt('lunch_minute') ?? 0;
    final dH = prefs.getInt('dinner_hour') ?? 19;
    final dM = prefs.getInt('dinner_minute') ?? 0;



    NotificationService().scheduleNotification(
      id: NotificationService.breakfastId,
      channelId: NotificationService.mealChannelId,
      channelName: 'Meal Reminders',
      title: 'Meal Reminder',
      body: 'Time for breakfast!',
      scheduledDateTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, bH, bM
      ),
      repeatDaily: true,
    );
    NotificationService().scheduleNotification(
      id: NotificationService.lunchId,
      channelId: NotificationService.mealChannelId,
      channelName: 'Meal Reminders',
      title: 'Meal Reminder',
      body: 'Time for lunch!',
      scheduledDateTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, lH, lM
      ),
      repeatDaily: true,
    );
    NotificationService().scheduleNotification(
      id: NotificationService.dinnerId,
      channelId: NotificationService.mealChannelId,
      channelName: 'Meal Reminders',
      title: 'Meal Reminder',
      body: 'Time for dinner!',
      scheduledDateTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, dH, dM
      ),
      repeatDaily: true,
    );
  }

  // — Water Reminders (single time example; adapt if you support multiple) —
  final waterEnabled = prefs.getBool('water_enabled') ?? false;
  if (waterEnabled) {
    final h = prefs.getInt('water_hour') ?? 9;
    final m = prefs.getInt('water_minute') ?? 0;
    NotificationService().scheduleNotification(
      id: NotificationService.waterId,
      channelId: NotificationService.waterChannelId,
      channelName: 'Water Intake Reminders',
      title: 'Water Reminder',
      body: 'Time to drink water!',
      scheduledDateTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, h, m
      ),
      repeatDaily: true,
    );
  }

  // — Exercise Prompts —
  final exerciseEnabled = prefs.getBool('exercise_enabled') ?? false;
  if (exerciseEnabled) {
    final h = prefs.getInt('exercise_hour') ?? 18;
    final m = prefs.getInt('exercise_minute') ?? 0;
    NotificationService().scheduleNotification(
      id: NotificationService.exerciseId,
      channelId: NotificationService.exerciseChannelId,
      channelName: 'Exercise Prompts',
      title: 'Exercise Reminder',
      body: 'Time for your daily workout!',
      scheduledDateTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, h, m
      ),
      repeatDaily: true,
    );
  }

  // — Goal Achievement Alerts —
  final goalEnabled = prefs.getBool('goal_alert_enabled') ?? false;
  if (goalEnabled) {
    final h = prefs.getInt('goal_alert_hour') ?? 20;
    final m = prefs.getInt('goal_alert_minute') ?? 0;
    NotificationService().scheduleNotification(
      id: NotificationService.goalId,
      channelId: NotificationService.goalChannelId,
      channelName: 'Goal Achievement Alerts',
      title: 'Goal Check',
      body: 'Check if you’ve reached 1420 calories!',
      scheduledDateTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, h, m
      ),
      repeatDaily: true,
    );
  }

  // — Inactivity Alerts —
  final inactivityEnabled = prefs.getBool('inactivity_alert_enabled') ?? false;
  if (inactivityEnabled) {
    final h = prefs.getInt('inactivity_alert_hour') ?? 21;
    final m = prefs.getInt('inactivity_alert_minute') ?? 0;
    NotificationService().scheduleNotification(
      id: NotificationService.inactivityId,
      channelId: NotificationService.inactivityChannelId,
      channelName: 'Inactivity Alerts',
      title: 'Inactivity Alert',
      body: 'You’ve been inactive for 48h!',
      scheduledDateTime: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, h, m
      ),
      repeatDaily: true,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriStep',
      debugShowCheckedModeBanner: false,
      theme: appTheme,

      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/welcome': (ctx) => const WelcomeScreen(),
        '/login':   (ctx) => const LoginScreen(),
        '/dashboard': (ctx) => const DashboardScreen(),
        '/add_breakfast': (ctx) =>
            AddFoodPage(mealType: 'breakfast', userId: FirebaseAuth.instance.currentUser!.uid),
        '/add_lunch': (ctx) =>
            AddFoodPage(mealType: 'lunch', userId: FirebaseAuth.instance.currentUser!.uid),
        '/add_dinner': (ctx) =>
            AddFoodPage(mealType: 'dinner', userId: FirebaseAuth.instance.currentUser!.uid),
        '/log_water': (ctx) => AddWaterPage(userId: FirebaseAuth.instance.currentUser!.uid),
        '/log_exercise': (ctx) => AddCardioPage(userId: FirebaseAuth.instance.currentUser!.uid),
        '/notifications': (ctx) => const NotificationsPage(),
      },
    );
  }
}







