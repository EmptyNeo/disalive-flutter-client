import 'package:disalive/presentation/features/home/bottom_system_inset_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('switching from button navigation to gestures reduces the inset', () {
    final tracker = BottomSystemInsetTracker();

    tracker.updateFromMediaQuery(48);
    expect(tracker.inset, 48);

    tracker.updateFromMediaQuery(24);
    expect(tracker.inset, 24);

    tracker.updateFromMediaQuery(0);
    expect(tracker.inset, 24);
  });

  test('fresh Android inset wins over a stale MediaQuery value', () {
    final tracker = BottomSystemInsetTracker();

    tracker.updateFromMediaQuery(48);
    expect(tracker.updateFromPlatform(24), isTrue);
    tracker.updateFromMediaQuery(48);
    expect(tracker.inset, 24);

    expect(tracker.updateFromPlatform(0), isTrue);
    expect(tracker.inset, 0);
  });
}
