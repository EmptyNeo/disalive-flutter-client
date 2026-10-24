import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/members/member_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('role uses free width beside a short display name', (
    tester,
  ) async {
    const roleName = 'Длинное название роли';
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: SizedBox(
            width: 420,
            child: MemberItem(
              member: const Member(
                user: UserModel(displayName: 'А'),
                role: RoleMember(name: roleName),
              ),
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('member_role')), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(roleName));
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
