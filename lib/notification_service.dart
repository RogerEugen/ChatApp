// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings settings =
//         InitializationSettings(android: androidSettings);

//     await _notifications.initialize(settings);
//   }

//   static Future<void> showNotification(
//       String title, String body) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'chat_channel',
//       'Chat Messages',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const NotificationDetails details =
//         NotificationDetails(android: androidDetails);

//     await _notifications.show(
//       0,
//       title,
//       body,
//       details,
//     );
//   }
// }
