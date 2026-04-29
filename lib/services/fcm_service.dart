import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Handle background messages (Must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to initialize Firebase here, do it.
  print("Handling a background message: ${message.messageId}");
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request Permissions (iOS & Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Subscribe to topics based on your Laravel logic
    // Since this is the student app, we subscribe to 'students' and 'both'
    await _messaging.subscribeToTopic('students');
    await _messaging.subscribeToTopic('both');

    // 4. Configure local notifications for foreground display
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
                presentSound: true, presentAlert: true),
          ),
          payload: message.data['type'], // Pass the 'type' from Laravel
        );
      }
    });

    // 6. Handle tap on notification when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data, navigatorKey);
    });

    // 7. Handle tap on notification when app is terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay navigation slightly to ensure the app UI is fully mounted
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(initialMessage.data, navigatorKey);
      });
    }
  }

  // Routing logic based on your Laravel 'type' payload
  void _handleNotificationTap(
      Map<String, dynamic> data, GlobalKey<NavigatorState> navigatorKey) {
    final type = data['type'];

    if (type == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'enrollment':
      case 'new_student':
        Navigator.pushNamed(context, '/my_courses');
        break;
      case 'course_start':
      case 'course_end':
        Navigator.pushNamed(context, '/progress');
        break;
      case 'custom_broadcast':
        // Show dialog or navigate to a general notifications screen
        break;
      default:
        Navigator.pushNamed(context, '/home');
    }
  }

  // Get FCM Token (If you need to send direct 'individual' notifications)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
