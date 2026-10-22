/// Keeps the navigation bar inset while Flutter temporarily reports zero
/// after leaving an immersive screen.
class BottomSystemInsetTracker {
  double? _lastReportedInset;
  double _inset = 0;

  double get inset => _inset;

  void updateFromMediaQuery(double reportedInset) {
    if (_lastReportedInset == reportedInset) return;
    _lastReportedInset = reportedInset;
    if (reportedInset > 0) _inset = reportedInset;
  }

  bool updateFromPlatform(double? platformInset) {
    if (platformInset == null || !platformInset.isFinite || platformInset < 0) {
      return false;
    }
    if (_inset == platformInset) return false;
    _inset = platformInset;
    return true;
  }
}
