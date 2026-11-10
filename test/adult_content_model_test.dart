import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('server adult flag survives response, cache and copy', () {
    final server = Server.fromMap({'id': 7, 'isAdult': true});
    expect(server.isAdult, isTrue);
    expect(
      Server.fromMap(server.toMap()).copyWith(name: 'Updated').isAdult,
      isTrue,
    );
    expect(Server.fromMap({'id': 7}).isAdult, isFalse);
  });

  test('channel adult flag survives response, cache and copy', () {
    final channel = ChannelServer.fromMap({
      'id': 9,
      'serverId': 7,
      'chatId': 12,
      'isAdult': 1,
    });
    expect(channel.isAdult, isTrue);
    expect(
      ChannelServer.fromMap(channel.toMap()).copyWith(members: []).isAdult,
      isTrue,
    );
    expect(ChannelServer.fromMap({'id': 9}).isAdult, isFalse);
  });
}
