import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/tabs/emojis_tab.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category navigation reaches sections not yet built', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final target = EmojisHandler.instance.categoryNames.last;
    await tester.pumpWidget(CupertinoApp(home: EmojisTab(onTap: (_) {})));
    await tester.pump();
    expect(find.text(target), findsNothing);

    final categoryBar = find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(categoryBar, const Offset(-1000, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('emoji-category-$target')));
    await tester.pumpAndSettle();
    expect(find.text(target), findsOneWidget);
    expect(tester.getTopLeft(find.text(target)).dy, lessThan(640));
  });

  testWidgets('emoji clips stay inside grid cells on narrow screens', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final width in [320.0, 240.0]) {
      tester.view.physicalSize = Size(width, 640);
      await tester.pumpWidget(CupertinoApp(home: EmojisTab(onTap: (_) {})));
      await tester.pump();

      final first = find.byType(EmojiWidget).at(0);
      final second = find.byType(EmojiWidget).at(1);
      final firstWidget = tester.widget<EmojiWidget>(first);
      final clip = find.descendant(of: first, matching: find.byType(ClipRect));
      expect(firstWidget.frameInset, 1);
      expect(tester.getSize(clip), Size.square(firstWidget.size));
      expect(
        tester.getRect(first).right,
        lessThan(tester.getRect(second).left),
      );
    }
  });
}
