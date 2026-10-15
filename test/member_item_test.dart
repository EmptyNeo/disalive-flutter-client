import 'package:disalive/domain/models/badge.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/members/member_item.dart';
import 'package:disalive/presentation/features/profile/items/badge_item.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('member shows role and main badge after display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: SizedBox(
            width: 250,
            child: MemberItem(
              member: const Member(
                user: UserModel(
                  displayName: 'Очень длинное имя участника',
                  mainBadge: BadgeModel(id: 1, name: 'Звезда'),
                ),
                role: RoleMember(name: 'Модератор', emoji: '⭐'),
              ),
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Модератор'), findsOneWidget);
    expect(find.byType(RoleEmoji), findsOneWidget);
    expect(tester.widget<BadgeItem>(find.byType(BadgeItem)).badge.id, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('emoji-only role is shown before badge', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MemberItem(
            member: const Member(
              user: UserModel(
                displayName: 'Алиса',
                mainBadge: BadgeModel(id: 2),
              ),
              role: RoleMember(emoji: '🔥'),
            ),
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(find.byType(RoleEmoji), findsOneWidget);
    expect(find.byType(BadgeItem), findsOneWidget);
    expect(find.text('Роль'), findsNothing);
  });

  testWidgets('role card and badge stay next to a short name', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: SizedBox(
            width: 500,
            child: MemberItem(
              member: const Member(
                user: UserModel(
                  displayName: 'Алиса',
                  mainBadge: BadgeModel(id: 3),
                ),
                role: RoleMember(name: 'Модератор', emoji: '⭐'),
              ),
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );

    final roleFinder = find.byKey(const ValueKey('member_role'));
    final nameRight = tester.getTopRight(find.text('Алиса')).dx;
    final roleLeft = tester.getTopLeft(roleFinder).dx;
    final roleRight = tester.getTopRight(roleFinder).dx;
    final badgeLeft = tester.getTopLeft(find.byType(BadgeItem)).dx;
    expect(roleLeft - nameRight, closeTo(5, 0.1));
    expect(badgeLeft - roleRight, closeTo(5, 0.1));

    final decoration = tester.widget<Container>(roleFinder).decoration;
    expect(decoration, isA<BoxDecoration>());
    expect((decoration! as BoxDecoration).borderRadius, isNotNull);
  });
}
