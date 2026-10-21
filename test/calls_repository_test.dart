import 'dart:convert';

import 'package:disalive/data/repositories/calls_repository_impl.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

void main() {
  const chat = EntityKey(entityId: 12, entityType: EntityType.chat);
  const server = EntityKey(entityId: 3, entityType: EntityType.server);

  test('getToken posts entity context and parses LiveKit token', () async {
    late http.Request request;
    final client = HttpClientService(
      client: MockClient((sent) async {
        request = sent;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'jwt', 'userId': 8, 'chatId': '12'},
          }),
          200,
        );
      }),
      secureStorage: _Storage(),
    );
    addTearDown(client.dispose);

    final result = await CallsRepositoryImpl(
      httpClient: client,
    ).getToken(chatId: 12, entityKey: chat, lastIdMessage: 50);

    expect(request.url.path, '/v1/calls/get.php');
    expect(request.bodyFields, containsPair('keySession', 'session-key'));
    expect(request.bodyFields, containsPair('chatId', '12'));
    expect(request.bodyFields, containsPair('entityId', '12'));
    expect(request.bodyFields, containsPair('entityType', 'chat'));
    expect(request.bodyFields, containsPair('lastIdMessage', '50'));
    final token = result.getOrElse(() => throw StateError('token failed'));
    expect(token.token, 'jwt');
    expect(token.userId, 8);
    expect(token.chatId, 12);
  });

  test('participants supports all server rooms and parses tracks', () async {
    late http.Request request;
    final client = HttpClientService(
      client: MockClient((sent) async {
        request = sent;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'rooms': {
                '21': [
                  {
                    'identity': '8',
                    'name': 'User',
                    'metadata': '{"displayName":"Alex"}',
                    'tracks': [
                      {
                        'sid': 'track-1',
                        'type': 1,
                        'name': 'mic',
                        'source': 'microphone',
                        'muted': false,
                        'mimeType': 'audio/opus',
                      },
                    ],
                    'startedAt': 1000,
                    'serverNow': 2000,
                  },
                ],
                '22': [],
              },
            },
          }),
          200,
        );
      }),
      secureStorage: _Storage(),
    );
    addTearDown(client.dispose);

    final repository = CallsRepositoryImpl(httpClient: client);
    final result = await repository.getParticipants(entityKey: server);

    expect(request.url.path, '/v1/calls/participants.php');
    expect(request.bodyFields, containsPair('entityId', '3'));
    expect(request.bodyFields, containsPair('entityType', 'server'));
    expect(request.bodyFields.containsKey('chatId'), isFalse);
    final rooms = result.getOrElse(() => throw StateError('rooms failed'));
    expect(rooms.forChat(21).single.metadata['displayName'], 'Alex');
    expect(rooms.forChat(21).single.tracks.single.source, 'microphone');
    expect(rooms.forChat(22), isEmpty);
  });

  test('kick sends custom ISO expiration without timeoutMinutes', () async {
    late http.Request request;
    final client = HttpClientService(
      client: MockClient((sent) async {
        request = sent;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'callBan': {'id': 7, 'expiresAt': '2026-10-21 12:00:00'},
            },
          }),
          200,
        );
      }),
      secureStorage: _Storage(),
    );
    addTearDown(client.dispose);

    final result = await CallsRepositoryImpl(httpClient: client).kick(
      chatId: 21,
      entityKey: server,
      targetUserId: 8,
      expiresAt: DateTime.parse('2026-10-21T15:00:00+03:00'),
    );

    expect(request.url.path, '/v1/calls/kick.php');
    expect(request.bodyFields, containsPair('chatId', '21'));
    expect(request.bodyFields, containsPair('entityId', '3'));
    expect(request.bodyFields, containsPair('entityType', 'server'));
    expect(request.bodyFields, containsPair('targetUserId', '8'));
    expect(
      request.bodyFields,
      containsPair('expiresAt', '2026-10-21T12:00:00.000Z'),
    );
    expect(request.bodyFields.containsKey('timeoutMinutes'), isFalse);
    expect(result.getOrElse(() => throw StateError('kick failed')).id, 7);
  });

  test(
    'kick without timeout sends zero, unban accepts an empty array',
    () async {
      final requests = <http.Request>[];
      final client = HttpClientService(
        client: MockClient((sent) async {
          requests.add(sent);
          if (sent.url.path.endsWith('/kick.php')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'callBan': {'id': 9, 'expiresAt': null},
                },
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }),
        secureStorage: _Storage(),
      );
      addTearDown(client.dispose);
      final repository = CallsRepositoryImpl(httpClient: client);

      final kicked = await repository.kick(
        chatId: 12,
        entityKey: chat,
        targetUserId: 8,
      );
      final unbanned = await repository.unban(entityKey: chat, targetUserId: 8);

      expect(requests.first.bodyFields, containsPair('timeoutMinutes', '0'));
      expect(requests.first.bodyFields.containsKey('expiresAt'), isFalse);
      expect(
        kicked.getOrElse(() => throw StateError('kick failed')).expiresAt,
        isNull,
      );
      expect(requests.last.url.path, '/v1/calls/unban.php');
      expect(requests.last.bodyFields, containsPair('targetUserId', '8'));
      expect(unbanned.getOrElse(() => false), isTrue);
    },
  );
}
