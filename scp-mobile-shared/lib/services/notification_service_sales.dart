import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../services/http_service.dart';

/// Notification service for supplier sales app
class NotificationServiceSales {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final HttpService _httpService;

  NotificationServiceSales({
    FlutterLocalNotificationsPlugin? localNotifications,
    HttpService? httpService,
  })  : _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _httpService = httpService ?? HttpService();

  /// Initialize notification service
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate based on notification payload
    if (response.payload != null) {
      // Handle navigation
    }
  }

  /// Get all notifications
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _httpService.get(
        '/supplier/notifications',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (unreadOnly) 'unread_only': true,
        },
      );

      // Handle both paginated format (results) and direct format (data)
      final dynamic payload = response.data;
      final List<dynamic> data = (payload is Map && payload['results'] != null)
          ? payload['results'] as List<dynamic>
          : (payload is Map && payload['data'] != null)
              ? payload['data'] as List<dynamic>
              : (payload is List)
                  ? payload
                  : <dynamic>[];
      return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _httpService.post('/supplier/notifications/$notificationId/read');
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _httpService.post('/supplier/notifications/mark-all-read');
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'scp_notifications',
      'SCP Notifications',
      channelDescription: 'Notifications for SCP Supplier Sales App',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

