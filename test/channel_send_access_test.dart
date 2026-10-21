import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/presentation/features/chat/channel_send_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const server = Server(id: 1, fkOwner: 10, roleId: 30);

  test('public channel permits messages without access lists', () {
    expect(
      canSendToChannel(
        channel: const ChannelServer(chatId: 2),
        server: server,
        userId: 20,
        roleId: 30,
      ),
      isTrue,
    );
  });

  test('private channel permits an explicitly allowed user or role', () {
    const channel = ChannelServer(
      chatId: 2,
      isPrivate: true,
      allowedUsers: [20],
      allowedRoles: [40],
    );
    expect(
      canSendToChannel(
        channel: channel,
        server: server,
        userId: 20,
        roleId: 30,
      ),
      isTrue,
    );
    expect(
      canSendToChannel(
        channel: channel,
        server: server,
        userId: 21,
        roleId: 40,
      ),
      isTrue,
    );
    expect(
      canSendToChannel(
        channel: channel,
        server: server,
        userId: 21,
        roleId: 30,
      ),
      isFalse,
    );
  });

  test('server owner retains access and missing channel denies sending', () {
    const channel = ChannelServer(chatId: 2, isPrivate: true);
    expect(
      canSendToChannel(
        channel: channel,
        server: server,
        userId: 10,
        roleId: 30,
      ),
      isTrue,
    );
    expect(
      canSendToChannel(channel: null, server: server, userId: 10, roleId: 30),
      isFalse,
    );
  });
}
