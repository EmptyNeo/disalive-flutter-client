import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/services/adult_content_access_service.dart';
import 'package:disalive/presentation/widgets/adult_content_notice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adult access changes on the eighteenth birthday', () {
    final today = DateTime.utc(2026, 11, 10);
    expect(
      AdultContentAccessService.isAdult('2008-11-10', today: today),
      isTrue,
    );
    expect(
      AdultContentAccessService.isAdult('2008-11-11', today: today),
      isFalse,
    );
    expect(
      AdultContentAccessService.isAdult('10.11.2008', today: today),
      isTrue,
    );
    expect(AdultContentAccessService.isAdult(null, today: today), isFalse);
    expect(
      AdultContentAccessService.isAdult('2008-02-30', today: today),
      isFalse,
    );
  });

  test('only adult content requires an adult user', () {
    expect(const Server(isAdult: true).canAccess(userIsAdult: false), isFalse);
    expect(const Server(isAdult: true).canAccess(userIsAdult: true), isTrue);
    expect(const Server().canAccess(userIsAdult: false), isTrue);
    expect(
      const ChannelServer(isAdult: true).canAccess(userIsAdult: false),
      isFalse,
    );
    expect(
      const ChannelServer(isAdult: true).canAccess(userIsAdult: true),
      isTrue,
    );
    expect(const ChannelServer().canAccess(userIsAdult: false), isTrue);
  });

  testWidgets(
    'adult content notice wraps its text instead of filling the screen',
    (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 500,
              child: Align(
                alignment: Alignment.topCenter,
                child: AdultContentNotice(
                  description: 'Доступ к каналам запрещён.',
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AdultContentNotice)).height,
        lessThan(150),
      );
    },
  );
}
