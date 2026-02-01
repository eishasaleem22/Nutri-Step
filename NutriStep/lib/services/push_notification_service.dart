import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles all Firebase Cloud Messaging setup and logic.
class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Call this from main() before runApp()
  Future<void> init() async {
    // 1) Background handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // 2) Request user permissions (iOS)
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // 3) Grab the token
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) await _saveTokenToFirestore(token);
    }

    // 4) Foreground message listener
    FirebaseMessaging.onMessage.listen(_onMessage);

    // 5) When opened from a notification:
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  /// Background message handler
  static Future<void> _backgroundHandler(RemoteMessage msg) async {
    // Note: you may need to call Firebase.initializeApp() if you use other Firebase APIs
    print('⏰ BG message: ${msg.messageId}');
  }

  /// Save the FCM token under users/{uid}/fcmToken
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  /// Called when the app is in foreground and a message arrives
  void _onMessage(RemoteMessage msg) {
    print('📩 Foreground message: ${msg.notification?.title}');
    // TODO: show in-app banner or local notification
  }

  /// Called when the user taps a notification to open the app
  void _onMessageOpenedApp(RemoteMessage msg) {
    print('🔔 Notification clicked!');
    // TODO: navigate to a specific screen
  }
}
