import 'package:disalive/domain/enums/request_type.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'profile request is parsed as a FriendRequest and survives serialization',
    () {
      final user = UserModel.fromMap({
        'id': 7,
        'username': 'alex',
        'friendRequest': {
          'id': 42,
          'senderId': 7,
          'receiverId': 9,
          'type': 'outgoing',
        },
      });

      expect(user.friendRequest?.id, 42);
      expect(user.friendRequest?.type, RequestType.outgoing);
      expect(UserModel.fromMap(user.toMap()).friendRequest, user.friendRequest);
    },
  );

  test('profile without request keeps friendRequest null', () {
    expect(UserModel.fromMap({'id': 7}).friendRequest, isNull);
  });
}
