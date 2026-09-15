import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/features/requests/requests_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:disalive/main.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint(
    "Firebase поймал пуш в фоне (ОС сама отобразит его): ${message.messageId}",
  );
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'disalive_channel',
      'Disalive',
      description: 'Уведомления Disalive',
      importance: Importance.max,
      playSound: true,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          '➡️ Клик по ЛОКАЛЬНОМУ уведомлению во foreground. Payload: ${response.payload}',
        );
        final String? payload = response.payload;
        if (payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            _onNotificationTap(RemoteMessage(data: data));
          } catch (e) {
            debugPrint('Ошибка обработки локального уведомления: $e');
          }
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('Системный канал уведомлений Android создан успешно');
    }

    _setupHandlers();

    _isInitialized = true;
  }

  Future<void> requestPermissionsAndRegisterToken() async {
    if (!_isInitialized) await init();

    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        debugPrint('Android POST_NOTIFICATIONS разрешение: $granted');
      }

      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      //обновить токен fcmToken через репозиторий пользователя
    } catch (e) {
      debugPrint('Ошибка при запросе разрешений: $e');
    }
  }

  Future<void> registerTokenOnly() async {
    if (!_isInitialized) await init();

    try {
      //обновить токен fcmToken через репозиторий пользователя
    } catch (e) {
      debugPrint('Ошибка при обновлении токена: $e');
    }
  }

  void _setupHandlers() {
    debugPrint('Установка слушателей Firebase Messaging...');

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('➡️ Получен пуш в Foreground: ${message.messageId}');
      _showNotification(message);
    });

    // Приложение в фоне (Background) — юзер кликнул по системной шторке
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '➡️ Юзер КЛИКНУЛ по системному уведомлению (Приложение было в фоне)',
      );
      _onNotificationTap(message);
    });
  }

  Future<void> checkInitialMessage() async {
    debugPrint('Проверка InitialMessage (Холодный старт)...');
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      debugPrint('➡️ Найдено сообщение холодного старта: ${message.messageId}');
      _onNotificationTap(message);
    }
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final String payloadData = jsonEncode(message.data);

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'disalive_channel',
          'Disalive',
          channelDescription: 'Уведомления Disalive',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payloadData,
    );
  }

  void _onNotificationTap(RemoteMessage? message) async {
    if (message == null) return;

    final type = message.data['type'] ?? 'new_message';

    int attempts = 0;
    while (navigatorKey.currentState == null && attempts < 25) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'new_message':
        final chatId = message.data['chatId'];
        if (chatId != null) {
          final chatRepo = sl<ChatRepository>();
          final result = await chatRepo.get();
          result.fold((err) => debugPrint('Чат не найден: $err'), (chats) {
            final chat = chats.where((c) => c.id == chatId).first;
            ChatScreen.open(context, chat, false);
          });
        }
        break;
      case 'friend_request':
        if (context.mounted) {
          RequestsScreen.open(context);
        }
        break;
      default:
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(MyRouter.home, (route) => false);
        }
        break;
    }
  }
}
