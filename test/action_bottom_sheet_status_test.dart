import 'package:disalive/domain/enums/user_status.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/status_dot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('action sheet renders status dot and explanation', (tester) async {
    var selected = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => ActionBottomSheet.show(
              context,
              actions: [
                ActionItem(
                  icon: CupertinoIcons.circle_fill,
                  leading: const StatusDot(status: UserStatus.dnd, size: 18),
                  label: UserStatus.dnd.displayStatus,
                  subtitle: 'Вы не будете получать уведомление',
                  onTap: () => selected = true,
                ),
              ],
            ),
            child: const Text('Открыть'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.byType(StatusDot), findsOneWidget);
    expect(find.text('Не беспокоить'), findsOneWidget);
    expect(find.text('Вы не будете получать уведомление'), findsOneWidget);

    await tester.tap(find.text('Не беспокоить'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
  });
}
