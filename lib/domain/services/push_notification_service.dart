import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/services/crop_to_circle.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/features/calls/call_screen.dart';
import 'package:disalive/presentation/features/home/home_screen.dart';
import 'package:disalive/presentation/features/requests/requests_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;

// Message из плагина уведомлений — отдельно, с префиксом, чтобы не конфликтовал
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln
    show Message;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔔 Firebase поймал пуш в фоне: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

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
      '@mipmap/ic_launcher',
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
          '➡️ Клик по уведомлению (Foreground). Payload: ${response.payload}',
        );
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _onNotificationTap(RemoteMessage(data: data));
          } catch (e) {
            debugPrint('Ошибка обработки payload: $e');
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
    }

    _setupHandlers();
    await checkInitialMessage();

    _isInitialized = true;
  }

  static Future<String?> getToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        return await messaging.getToken();
      }
      return null;
    } catch (e) {
      debugPrint('FCM Token retrieval error: $e');
      return null;
    }
  }

  void _setupHandlers() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('➡️ Получен пуш в Foreground: ${message.messageId}');
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('➡️ Клик по системному уведомлению (Background)');
      _onNotificationTap(message);
    });
  }

  Future<void> checkInitialMessage() async {
    debugPrint('🔍 Проверка InitialMessage (Холодный старт)...');

    // 1. Запуск из системного FCM-уведомления
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      debugPrint('➡️ Найдено сообщение холодного старта: ${message.messageId}');
      _onNotificationTap(message);
      return;
    }

    // 2. Запуск из локального уведомления
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null) {
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _onNotificationTap(RemoteMessage(data: data));
        } catch (e) {
          debugPrint('Ошибка payload при холодном старте: $e');
        }
      }
    }
  }

  /// Скачивает аватар в память. Возвращает null при любой ошибке.
  Future<Uint8List?> _downloadAvatar(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) return null;

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 5))) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } catch (e) {
      debugPrint('Не удалось скачать аватар: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<BuildContext?> _waitForHomeContext() async {
    for (var i = 0; i < 60; i++) {
      final ctx = HomeScreen.scopeContext;
      if (ctx != null && ctx.mounted) return ctx;
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final String payloadData = jsonEncode(message.data);
    final String? avatarUrl = message.data['avatarUrl'];

    Uint8List? avatarBytes;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarBytes = await _downloadAvatar(avatarUrl);
      if (avatarBytes != null) {
        try {
          avatarBytes = await circleCrop(avatarBytes);
        } catch (e) {
          debugPrint('Не удалось скруглить аватар: $e'); // останется как есть
        }
      }
    }

    final Person sender = Person(
      name: notification.title ?? 'Отправитель',
      icon: avatarBytes != null ? ByteArrayAndroidIcon(avatarBytes) : null,
    );

    final styleInformation = MessagingStyleInformation(
      sender,
      conversationTitle: notification.title,
      messages: [fln.Message(notification.body ?? '', DateTime.now(), sender)],
    );

    await _localNotifications.show(
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
          styleInformation: styleInformation,
          largeIcon: avatarBytes != null
              ? ByteArrayAndroidBitmap(avatarBytes)
              : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payloadData,
    );
  }

  void _onNotificationTap(RemoteMessage? message) async {
    if (message == null) return;

    final type = message.data['type'];

    switch (type) {
      case 'new_call':
        final int? chatId = int.tryParse('${message.data['chatId']}');
        if (chatId == null) return;

        final homeContext = await _waitForHomeContext();
        if (homeContext == null) {
          debugPrint('❌ HomeScreen не готов, не могу открыть звонок');
          return;
        }

        final result = await sl<ChatRepository>().get();
        if (!homeContext.mounted) return;

        result.fold((err) => debugPrint('Чат звонка не найден: $err'), (chats) {
          final chat = chats.where((c) => c.id == chatId).firstOrNull;
          if (chat == null) {
            debugPrint('Чат звонка $chatId не найден в списке');
            return;
          }
          CallScreen.open(
            homeContext,
            chatId: chatId,
            entityKey: EntityKey(entityId: chatId, entityType: EntityType.chat),
            title: chat.name,
            lastIdMessage: chat.idLastMessage,
          );
        });
        break;

      case 'new_message':
        final int? chatId = int.tryParse('${message.data['chatId']}');
        if (chatId == null) return;

        final homeContext = await _waitForHomeContext();
        if (homeContext == null) {
          debugPrint('❌ HomeScreen не готов, не могу открыть чат');
          return;
        }

        final result = await sl<ChatRepository>().get();
        if (!homeContext.mounted) return;

        result.fold((err) => debugPrint('Чат не найден: $err'), (chats) {
          final chat = chats.where((c) => c.id == chatId).firstOrNull;
          if (chat != null) {
            ChatScreen.open(homeContext, chat, false);
          } else {
            debugPrint('Чат $chatId не найден в списке');
          }
        });
        break;

      case 'friend_request':
        final homeContext = await _waitForHomeContext();
        if (homeContext != null && homeContext.mounted) {
          RequestsScreen.open(homeContext);
        }
        break;

      default:
        // Уже на главной или на неизвестном типе — ничего не делаем
        break;
    }
  }
}
