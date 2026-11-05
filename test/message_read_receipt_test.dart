import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/chat/widgets/messages_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isMessageReadByAny', () {
    const message = Message(id: 100, userId: 7);

    test('does not count the current user as a reader', () {
      expect(
        isMessageReadByAny(
          message: message,
          currentUserId: 7,
          members: const [
            Member(fkUser: 7, isSelf: true, lastIdReadMessage: 100),
            Member(fkUser: 8, lastIdReadMessage: 99),
          ],
        ),
        isFalse,
      );
    });

    test('does not mark as read when the channel has no reader data', () {
      expect(
        isMessageReadByAny(message: message, currentUserId: 7, members: null),
        isFalse,
      );
    });

    test('marks as read when another member has read the message', () {
      expect(
        isMessageReadByAny(
          message: message,
          currentUserId: 7,
          members: const [
            Member(fkUser: 7, isSelf: true, lastIdReadMessage: 100),
            Member(fkUser: 8, lastIdReadMessage: 100),
          ],
        ),
        isTrue,
      );
    });

    test('reads per-member cursors from a server channel response', () {
      final channel = ChannelServer.fromMap({
        'members': [
          {'userId': '7', 'lastIdReadMessage': '100'},
          {'userId': '8', 'lastIdReadMessage': '100'},
        ],
      });

      expect(
        isMessageReadByAny(
          message: message,
          currentUserId: 7,
          members: channel.members,
        ),
        isTrue,
      );
      expect(channel.members.first.fkUser, 7);
      expect(channel.members.first.lastIdReadMessage, 100);
    });
  });
}
