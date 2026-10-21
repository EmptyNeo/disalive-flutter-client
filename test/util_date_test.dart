import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:flutter_test/flutter_test.dart';

String _backendUtc(DateTime local) => local
    .toUtc()
    .toIso8601String()
    .replaceFirst('T', ' ')
    .replaceFirst('Z', '');

void main() {
  test('day separators use the same local date as message times', () {
    final now = DateTime.now();
    final before = DateTime(now.year, now.month, now.day, 2, 58);
    final after = DateTime(now.year, now.month, now.day, 3, 12);

    expect(UtilDate.formatTime(_backendUtc(before)), '02:58');
    expect(UtilDate.formatTime(_backendUtc(after)), '03:12');
    expect(UtilDate.formatDayTime(_backendUtc(before), true), 'Сегодня');
    expect(UtilDate.formatDayTime(_backendUtc(after), true), 'Сегодня');
  });

  test('explicit timezone offset is not interpreted as UTC again', () {
    const raw = '2026-10-17T03:12:00+03:00';
    expect(UtilDate.parseDateTime(raw), DateTime.parse(raw).toLocal());
  });
}
