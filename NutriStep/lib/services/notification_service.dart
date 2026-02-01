// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;



/// A singleton service that manages all local notifications for:
///  • Meal reminders (breakfast, lunch, dinner)
///  • Water reminders
///  • Exercise prompts
///  • Goal achievement alerts
///  • Inactivity alerts
///
/// This version ensures:
///  1) We never accidentally schedule the same ID twice (no duplicates).
///  2) Calling `cancelChannelNotifications(...)` truly stops all future alarms for that channel.
///  3) Any “leftover” stale timers from a previous run are canceled before we schedule new ones.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // --------------------------------------------------------------------------
  // 1) CHANNEL IDs & NOTIFICATION IDs
  // --------------------------------------------------------------------------
  static const String mealChannelId       = 'meal_reminders';
  static const String waterChannelId      = 'water_reminders';
  static const String exerciseChannelId   = 'exercise_reminders';
  static const String goalChannelId       = 'goal_alerts';
  static const String inactivityChannelId = 'inactivity_alerts';

  // Unique integer IDs for each reminder type:
  static const int breakfastId  = 100;
  static const int lunchId      = 101;
  static const int dinnerId     = 102;
  static const int waterId      = 200;
  static const int exerciseId   = 300;
  static const int goalId       = 400;
  static const int inactivityId = 500;

  // --------------------------------------------------------------------------
  // 2) INITIALIZE (call once, e.g. in main())
  // --------------------------------------------------------------------------
  ///
  ///  • Initializes the timezone database
  ///  • Initializes the FlutterLocalNotificationsPlugin
  ///  • Creates distinct Android channels for each reminder type
  ///
  Future<void> initNotification() async {
    // 2a) Initialize timezone package
    tz.initializeTimeZones();
    // Note: tz.local will now reflect the device’s local zone automatically.

    // 2b) Android initialization settings
    const androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    // If you have a different launcher icon, replace '@mipmap/ic_launcher'.

    // 2c) iOS initialization settings
    final iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        // (Optional) Handle a local notification on older iOS versions
      },
    );

    // 2d) Combine into overall initialization settings
    final initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    // 2e) Initialize the plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // (Optional) Handle user's tap on a notification when app is backgrounded/terminated
      },
    );

    // 2f) Create Android channels for each category
    await _createAndroidChannels();
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const mealChannel = AndroidNotificationChannel(
      mealChannelId,
      'Meal Reminders',
      description: 'Reminders for breakfast, lunch, and dinner',
      importance: Importance.max,
    );
    const waterChannel = AndroidNotificationChannel(
      waterChannelId,
      'Water Intake Reminders',
      description: 'Reminders to drink water',
      importance: Importance.max,
    );
    const exerciseChannel = AndroidNotificationChannel(
      exerciseChannelId,
      'Exercise Prompts',
      description: 'Reminders to exercise',
      importance: Importance.max,
    );
    const goalChannel = AndroidNotificationChannel(
      goalChannelId,
      'Goal Achievement Alerts',
      description: 'Alerts for reaching daily goals',
      importance: Importance.max,
    );
    const inactivityChannel = AndroidNotificationChannel(
      inactivityChannelId,
      'Inactivity Alerts',
      description: 'Alerts for 48+ hours of inactivity',
      importance: Importance.max,
    );

    // Actually create them on the device
    await androidPlugin.createNotificationChannel(mealChannel);
    await androidPlugin.createNotificationChannel(waterChannel);
    await androidPlugin.createNotificationChannel(exerciseChannel);
    await androidPlugin.createNotificationChannel(goalChannel);
    await androidPlugin.createNotificationChannel(inactivityChannel);
  }
  // inside NotificationService

  /// Returns all pending notifications.
  Future<List<PendingNotificationRequest>> getPendingRequests() {
    return _notificationsPlugin.pendingNotificationRequests();
  }

  /// Cancels *every* pending notification, regardless of ID or channel.
  Future<void> clearAllPending() async {
    final pending = await getPendingRequests();
    for (final req in pending) {
      await _notificationsPlugin.cancel(req.id);
    }
  }



  // --------------------------------------------------------------------------
  // 3) HELPER: Build NotificationDetails for a given channel
  // --------------------------------------------------------------------------
  NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // --------------------------------------------------------------------------
  // 4) SHOW NOW (IMMEDIATE NOTIFICATION)
  // --------------------------------------------------------------------------
  ///
  /// Use this for an immediate “Test Notification” or any alert that doesn’t repeat.
  /// Defaults to ID = 0 so that it never collides with your scheduled IDs.
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required String channelName,
  }) async {
    final details = _notificationDetails(
      channelId: channelId,
      channelName: channelName,
    );
    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  // --------------------------------------------------------------------------
  // 5) SCHEDULE A (DAILY) REMINDER
  // --------------------------------------------------------------------------
  ///
  /// If `repeatDaily` is true, the notification will fire every day at the
  /// given local DateTime's hour/minute. If the chosen time has already
  /// passed for “today,” it is automatically bumped to tomorrow.
  ///
  /// IMPORTANT: we call `_notificationsPlugin.cancel(id)` first so that if you
  /// call `scheduleNotification(...)` multiple times with the same `id`, you
  /// never end up with duplicate alarms.
  ///
  Future<void> scheduleNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    bool repeatDaily = false,
    String? payload,
  }) async {
    // Convert the local DateTime into a tz.TZDateTime in tz.local
    tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDateTime, tz.local);
    final tzNow = tz.TZDateTime.now(tz.local);

    // If repeatDaily and the chosen time is already past “now,” bump to tomorrow
    if (repeatDaily && !tzDate.isAfter(tzNow)) {
      tzDate = tzDate.add(const Duration(days: 1));
    }

    // ---- CANCEL any existing alarm with the same ID so duplicates never stack up ----
    await _notificationsPlugin.cancel(id);

    // Build the platform details
    final details = _notificationDetails(
      channelId: channelId,
      channelName: channelName,
    );

    // Now actually schedule it:
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      payload: payload,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
      repeatDaily ? DateTimeComponents.time : null,
    );
  }

  // --------------------------------------------------------------------------
  // 6) CANCEL A SPECIFIC REMINDER OR ENTIRE CHANNEL
  // --------------------------------------------------------------------------
  ///
  /// Call `cancelNotification(id)` if you only want to remove that one ID.
  /// Call `cancelChannelNotifications(...)` with `all: true` to clear *all*
  /// IDs belonging to that channel at once.
  ///
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelChannelNotifications({
    required String channelId,
    bool all = true,
  }) async {
    if (!all) return;

    switch (channelId) {
      case mealChannelId:
        await cancelNotification(breakfastId);
        await cancelNotification(lunchId);
        await cancelNotification(dinnerId);
        break;
      case waterChannelId:
        await cancelNotification(waterId);
        break;
      case exerciseChannelId:
        await cancelNotification(exerciseId);
        break;
      case goalChannelId:
        await cancelNotification(goalId);
        break;
      case inactivityChannelId:
        await cancelNotification(inactivityId);
        break;
      default:
        break;
    }
  }
}


// // lib/services/notification_service.dart
//
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
// /// A singleton service that manages all local notifications for:
// ///  • Meal reminders (breakfast, lunch, dinner)
// ///  • Water reminders
// ///  • Exercise prompts
// ///  • Goal achievement alerts
// ///  • Inactivity alerts
// ///
// /// This version does NOT rely on flutter_native_timezone. Instead, it uses the
// /// default tz.local (which assumes the device’s local zone if you schedule
// /// using a local DateTime).
// ///
// /// You can call:
// ///   NotificationService().initNotification()       // once in main()
// ///   NotificationService().showNow(...)             // immediate test
// ///   NotificationService().scheduleDaily(...)       // schedule daily
// ///   NotificationService().cancelChannel(...)       // cancel by channel/time
// class NotificationService {
//   NotificationService._internal();
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//
//   final FlutterLocalNotificationsPlugin _plugin =
//   FlutterLocalNotificationsPlugin();
//
//   /// --------------------------------------------------------------------------
//   /// 1) CHANNEL IDs & NOTIFICATION IDs
//   /// --------------------------------------------------------------------------
//   static const String mealChannelId = 'meal_reminders';
//   static const String waterChannelId = 'water_reminders';
//   static const String exerciseChannelId = 'exercise_reminders';
//   static const String goalChannelId = 'goal_alerts';
//   static const String inactivityChannelId = 'inactivity_alerts';
//
//   // Unique IDs for each reminder type
//   static const int breakfastId = 100;
//   static const int lunchId = 101;
//   static const int dinnerId = 102;
//   static const int waterIdBase = 200;       // water uses hour*100+minute
//   static const int exerciseId = 300;
//   static const int goalId = 400;
//   static const int inactivityId = 500;
//
//   /// --------------------------------------------------------------------------
//   /// 2) INITIALIZE
//   /// --------------------------------------------------------------------------
//   ///  • Initializes the timezone database
//   ///  • Initializes the FlutterLocalNotificationsPlugin
//   ///  • Creates all Android notification channels
//   Future<void> initNotification() async {
//     // 2a) Initialize timezone package
//     tz.initializeTimeZones();
//     // tz.local will default to the device’s local zone if DateTime passed is local.
//
//     // 2b) Android initialization settings
//     const androidSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//     // Replace '@mipmap/ic_launcher' with your actual launcher icon if needed.
//
//     // 2c) iOS initialization settings
//     final iosSettings = DarwinInitializationSettings(
//       requestSoundPermission: true,
//       requestBadgePermission: true,
//       requestAlertPermission: true,
//       onDidReceiveLocalNotification:
//           (int id, String? title, String? body, String? payload) async {
//         // handle older iOS foreground notifications if needed
//       },
//     );
//
//     // 2d) Combine into overall initialization settings
//     final initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     // 2e) Initialize the plugin
//     await _plugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse:
//           (NotificationResponse response) async {
//         // Handle taps on notifications when app is backgrounded/terminated
//       },
//     );
//
//     // 2f) Create Android channels
//     await _createAndroidChannels();
//   }
//
//   Future<void> _createAndroidChannels() async {
//     const mealChannel = AndroidNotificationChannel(
//       mealChannelId,
//       'Meal Reminders',
//       description: 'Daily breakfast, lunch, and dinner reminders',
//       importance: Importance.high,
//     );
//     const waterChannel = AndroidNotificationChannel(
//       waterChannelId,
//       'Water Intake Reminders',
//       description: 'Daily water drinking reminders',
//       importance: Importance.high,
//     );
//     const exerciseChannel = AndroidNotificationChannel(
//       exerciseChannelId,
//       'Exercise Prompts',
//       description: 'Daily exercise reminders',
//       importance: Importance.high,
//     );
//     const goalChannel = AndroidNotificationChannel(
//       goalChannelId,
//       'Goal Achievement Alerts',
//       description: 'Alerts when you hit your daily calorie goal',
//       importance: Importance.high,
//     );
//     const inactivityChannel = AndroidNotificationChannel(
//       inactivityChannelId,
//       'Inactivity Alerts',
//       description: 'Alerts for 48+ hours of inactivity',
//       importance: Importance.high,
//     );
//
//     final androidPlugin = _plugin
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>();
//
//     if (androidPlugin != null) {
//       await androidPlugin.createNotificationChannel(mealChannel);
//       await androidPlugin.createNotificationChannel(waterChannel);
//       await androidPlugin.createNotificationChannel(exerciseChannel);
//       await androidPlugin.createNotificationChannel(goalChannel);
//       await androidPlugin.createNotificationChannel(inactivityChannel);
//     }
//   }
//
//   /// --------------------------------------------------------------------------
//   /// 3) HELPER: Build NotificationDetails for a given channel
//   /// --------------------------------------------------------------------------
//   NotificationDetails _platformDetailsForChannel(String channelId) {
//     final androidDetails = AndroidNotificationDetails(
//       channelId,
//       _channelName(channelId),
//       channelDescription: _channelDescription(channelId),
//       importance: Importance.max,
//       priority: Priority.max,
//       playSound: true,
//     );
//     const iosDetails = DarwinNotificationDetails();
//     return NotificationDetails(android: androidDetails, iOS: iosDetails);
//   }
//
//   String _channelName(String channelId) {
//     switch (channelId) {
//       case mealChannelId:
//         return 'Meal Reminders';
//       case waterChannelId:
//         return 'Water Intake Reminders';
//       case exerciseChannelId:
//         return 'Exercise Prompts';
//       case goalChannelId:
//         return 'Goal Achievement Alerts';
//       case inactivityChannelId:
//         return 'Inactivity Alerts';
//       default:
//         return 'General Notifications';
//     }
//   }
//
//   String _channelDescription(String channelId) {
//     switch (channelId) {
//       case mealChannelId:
//         return 'Daily breakfast, lunch, and dinner reminders';
//       case waterChannelId:
//         return 'Daily water drinking reminders';
//       case exerciseChannelId:
//         return 'Daily exercise reminders';
//       case goalChannelId:
//         return 'Alerts for hitting your daily calorie goal';
//       case inactivityChannelId:
//         return 'Alerts after 48 hours of no activity';
//       default:
//         return 'General notifications';
//     }
//   }
//
//   /// --------------------------------------------------------------------------
//   /// 4) SHOW NOW (IMMEDIATE TEST NOTIFICATION)
//   /// --------------------------------------------------------------------------
//   ///
//   /// Use this for a “Test Notification” button. Always uses id = 0 to avoid
//   /// clashing with any scheduled IDs.
//   Future<void> showNotification({
//     int id = 0,
//     required String channelId,
//     required String channelName,
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     final details = _platformDetailsForChannel(channelId);
//     await _plugin.show(id, title, body, details, payload: payload);
//   }
//
//   /// --------------------------------------------------------------------------
//   /// 5) SCHEDULE A DAILY REMINDER
//   /// --------------------------------------------------------------------------
//   ///
//   /// Schedules a notification that repeats every day at [hour]:[minute], local time.
//   /// We convert the given hour/minute into a local DateTime (today at that time).
//   /// If that time has already passed today, we bump to tomorrow.
//   ///
//   /// The [id] is computed, for meals:
//   ///   • breakfastId = 100
//   ///   • lunchId      = 101
//   ///   • dinnerId     = 102
//   ///   • water:         ID = hour*100+minute
//   ///   • exerciseId     = 300
//   ///   • goalId         = 400
//   ///   • inactivityId   = 500
//   ///
//   Future<void> scheduleDaily({
//     required int id,
//     required String channelId,
//     required String channelName,
//     required String title,
//     required String body,
//     required int hour,
//     required int minute,
//     bool repeatDaily = true,
//     String? payload,
//   }) async {
//     // Build a DateTime for “today at hour:minute”
//     final now = tz.TZDateTime.now(tz.local);
//     var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
//
//     // If that moment is in the past (or exactly now), bump to tomorrow
//     if (repeatDaily && !scheduled.isAfter(now)) {
//       scheduled = scheduled.add(const Duration(days: 1));
//     }
//
//     final details = _platformDetailsForChannel(channelId);
//
//     await _plugin.zonedSchedule(
//       id,
//       title,
//       body,
//       scheduled,
//       details,
//       payload: payload,
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//       UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
//     );
//   }
//
//   /// --------------------------------------------------------------------------
//   /// 6) CANCEL NOTIFICATIONS FOR A GIVEN CHANNEL OR ID
//   /// --------------------------------------------------------------------------
//   ///
//   /// If [hour] & [minute] are provided, we compute that single ID and cancel only
//   /// that one. Otherwise, we cancel *all* known IDs for that channel.
//   ///
//   Future<void> cancelChannel(
//       String channelId, {
//         int? hour,
//         int? minute,
//       }) async {
//     // If hour & minute are provided, compute that single ID and cancel it
//     if (hour != null && minute != null) {
//       final int id = _computeIdFromChannelAndTime(channelId, hour, minute);
//       await _plugin.cancel(id);
//       return;
//     }
//
//     // Otherwise cancel all known IDs for this channel
//     switch (channelId) {
//       case mealChannelId:
//         await _plugin.cancel(breakfastId);
//         await _plugin.cancel(lunchId);
//         await _plugin.cancel(dinnerId);
//         break;
//       case waterChannelId:
//       // We need to cancel every water reminder. If you stored waterTimes as
//       // a List<TimeOfDay> in prefs, you will loop over those and cancel by ID.
//       // But if you just want to cancel everything in the base ID range:
//       // We can only reliably cancel if we know which exact hours/minutes exist.
//       // For simplicity, let’s cancel any ID from 0..2359 (i.e. H*100+M) in steps:
//         for (int h = 0; h < 24; h++) {
//           for (int m = 0; m < 60; m++) {
//             final id = h * 100 + m;
//             await _plugin.cancel(id);
//           }
//         }
//         break;
//       case exerciseChannelId:
//         await _plugin.cancel(exerciseId);
//         break;
//       case goalChannelId:
//         await _plugin.cancel(goalId);
//         break;
//       case inactivityChannelId:
//         await _plugin.cancel(inactivityId);
//         break;
//       default:
//         break;
//     }
//   }
//
//   /// Cancel a single notification by ID
//   Future<void> cancelNotification(int id) async {
//     await _plugin.cancel(id);
//   }
//
//   /// --------------------------------------------------------------------------
//   /// 7) UTILITY: Compute a unique notification ID for (channel + hour/minute)
//   /// --------------------------------------------------------------------------
//   ///
//   /// Maps (channelId, hour, minute) to a fixed ID:
//   ///   • meal: breakfastId(100), lunchId(101), dinnerId(102)
//   ///   • water: h*100 + m
//   ///   • exerciseId: 300
//   ///   • goalId: 400
//   ///   • inactivityId: 500
//   int _computeIdFromChannelAndTime(
//       String channelId,
//       int hour,
//       int minute,
//       ) {
//     switch (channelId) {
//       case mealChannelId:
//         if (hour == 8 && minute == 0) return breakfastId;
//         if (hour == 13 && minute == 0) return lunchId;
//         if (hour == 19 && minute == 0) return dinnerId;
//         break;
//       case exerciseChannelId:
//         return exerciseId;
//       case goalChannelId:
//         return goalId;
//       case inactivityChannelId:
//         return inactivityId;
//       case waterChannelId:
//         return hour * 100 + minute;
//     }
//     // Fallback: combine hour & minute
//     return hour * 100 + minute;
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
