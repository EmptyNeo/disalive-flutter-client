import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/reactions_repository_impl.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/responses/reaction_summary_page.dart';
import 'package:disalive/domain/models/responses/reaction_users_page.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'test-session';
}

void main() {
  setUp(() async => sl.reset());
  tearDown(() async {
    if (sl.isRegistered<HttpClientService>()) {
      sl<HttpClientService>().dispose();
    }
    await sl.reset();
  });

  test('loads reaction summary and users with cursor parameters', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final isUsers = request.body.contains('nameReaction');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': isUsers
              ? {
                  'items': [
                    {
                      'cursor': 42,
                      'id': 9,
                      'username': 'neo',
                      'displayName': 'Empty Neo',
                      'pathImage': '/avatar.png',
                      'status': 'online',
                      'fontUsername': null,
                      'isNsfw': false,
                    },
                    {
                      'cursor': 43,
                      'id': 10,
                      'username': 'alice',
                      'displayName': 'Alice',
                      'pathImage': '/alice.png',
                      'status': 'offline',
                      'fontUsername': null,
                      'isNsfw': false,
                    },
                    {
                      'cursor': 44,
                      'id': 11,
                      'username': 'bob',
                      'displayName': 'Bob',
                      'pathImage': '/bob.png',
                      'status': 'idle',
                      'fontUsername': null,
                      'isNsfw': false,
                    },
                    {
                      'cursor': 45,
                      'id': 12,
                      'username': 'eve',
                      'displayName': 'Eve',
                      'pathImage': '/eve.png',
                      'status': 'dnd',
                      'fontUsername': null,
                      'isNsfw': false,
                    },
                  ],
                  'nextCursor': 45,
                  'hasMore': false,
                }
              : {
                  'items': [
                    {
                      'cursor': 12,
                      'nameReaction': '[default:smile]',
                      'amount': 5,
                    },
                  ],
                  'nextCursor': 12,
                  'hasMore': true,
                },
        }),
        200,
      );
    });
    sl.registerSingleton<HttpClientService>(
      HttpClientService(client: client, secureStorage: _TestStorage()),
    );
    final repository = ReactionsRepositoryImpl();

    final summaryResult = await repository.getByMessage(
      messageId: 3,
      entityId: 8,
      entityType: EntityType.server,
    );
    final usersResult = await repository.getUsersByMessage(
      messageId: 3,
      entityId: 8,
      entityType: EntityType.server,
      nameReaction: '[default:smile]',
      cursor: 12,
    );

    final summary = summaryResult.getOrElse(() => throw StateError('summary'));
    final users = usersResult.getOrElse(() => throw StateError('users'));
    expect(summary, isA<ReactionSummaryPage>());
    expect(summary.items.single.amount, 5);
    expect(summary.nextCursor, 12);
    expect(summary.hasMore, isTrue);
    expect(users, isA<ReactionUsersPage>());
    expect(users.items, hasLength(4));
    expect(users.items.first.displayName, 'Empty Neo');
    expect(users.items.map((user) => user.getDisplayName), [
      'Empty Neo',
      'Alice',
      'Bob',
      'Eve',
    ]);
    expect(users.nextCursor, 45);
    expect(users.hasMore, isFalse);
    for (final request in requests) {
      expect(request.url.path, '/v1/reactions/getByMessage.php');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(request.body, contains('name="messageId"'));
      expect(request.body, contains('\r\n\r\n3'));
      expect(request.body, contains('name="entityId"'));
      expect(request.body, contains('\r\n\r\n8'));
      expect(request.body, contains('name="entityType"'));
      expect(request.body, contains('\r\n\r\nserver'));
      expect(request.body, contains('name="keySession"'));
      expect(request.body, contains('\r\n\r\ntest-session'));
    }
    expect(requests[1].body, contains('name="nameReaction"'));
    expect(requests[1].body, contains('\r\n\r\n[default:smile]'));
    expect(requests[1].body, contains('name="cursor"'));
    expect(requests[1].body, contains('\r\n\r\n12'));
  });

  test('reaction page parsers read page objects and camelCase item data', () {
    final summary = ReactionSummaryPage.fromResponse({
      'items': [
        {'cursor': 15, 'nameReaction': '[default:heart]', 'amount': 4},
        {'cursor': 24, 'nameReaction': '[default:smile]', 'amount': 2},
      ],
      'nextCursor': 24,
      'hasMore': false,
    });
    final users = ReactionUsersPage.fromResponse({
      'items': [
        {
          'cursor': 31,
          'id': 9,
          'username': 'neo',
          'displayName': 'Empty Neo',
          'pathImage': '/avatar.png',
          'status': 'online',
          'fontUsername': null,
          'isNsfw': false,
        },
        {
          'cursor': 32,
          'id': 10,
          'username': 'alice',
          'displayName': 'Alice',
          'pathImage': '/alice.png',
          'status': 'offline',
          'fontUsername': null,
          'isNsfw': false,
        },
        {
          'cursor': 33,
          'id': 11,
          'username': 'bob',
          'displayName': 'Bob',
          'pathImage': '/bob.png',
          'status': 'idle',
          'fontUsername': null,
          'isNsfw': false,
        },
        {
          'cursor': 34,
          'id': 12,
          'username': 'eve',
          'displayName': 'Eve',
          'pathImage': '/eve.png',
          'status': 'dnd',
          'fontUsername': null,
          'isNsfw': false,
        },
      ],
      'nextCursor': 34,
      'hasMore': false,
    });

    expect(summary.items, hasLength(2));
    expect(summary.nextCursor, 24);
    expect(summary.hasMore, isFalse);
    expect(users.items, hasLength(4));
    expect(users.items.map((item) => item.id), [9, 10, 11, 12]);
    expect(users.items.map((item) => item.getDisplayName), [
      'Empty Neo',
      'Alice',
      'Bob',
      'Eve',
    ]);
    expect(users.nextCursor, 34);
  });
}
