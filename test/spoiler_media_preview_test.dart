import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/spoiler_media_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FileMessage parses spoiler values from API types', () {
    final file = FileMessage.fromMap({
      'isSpoiler': true,
      'mimeType': 'image/png',
      'originalName': 'hidden.png',
    });

    expect(file.isSpoilerFile, isTrue);
    expect(file.toMap()['isSpoiler'], 1);
  });

  testWidgets('first tap reveals spoiler and next tap triggers action', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: SizedBox(
              width: 200,
              height: 160,
              child: SpoilerMediaPreview(
                isSpoiler: true,
                onTapRevealed: () => opened++,
                childBuilder: (_, _) =>
                    const ColoredBox(color: CupertinoColors.systemRed),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('СПОЙЛЕР'), findsNothing);
    await tester.tap(find.byType(SpoilerMediaPreview));
    await tester.pump();
    expect(find.text('СПОЙЛЕР'), findsNothing);
    expect(opened, 0);

    await tester.tap(find.byType(SpoilerMediaPreview));
    expect(opened, 1);
  });

  testWidgets('lays out with finite media size in an unbounded row', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Row(
            children: [
              SpoilerMediaPreview(
                isSpoiler: true,
                childBuilder: (_, _) => SizedBox(
                  width: 120,
                  height: 84,
                  child: ColoredBox(color: CupertinoColors.systemRed),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(SpoilerMediaPreview)),
      const Size(120, 84),
    );
  });
}
