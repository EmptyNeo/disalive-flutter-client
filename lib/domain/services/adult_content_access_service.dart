import 'package:disalive/domain/repositories/user_repository.dart';

class AdultContentAccessService {
  const AdultContentAccessService(this._users);

  final UserRepository _users;

  bool get isCurrentUserAdult => isAdult(_users.getCurrentUser()?.dateOfBirth);

  static bool isAdult(String? birthDate, {DateTime? today}) {
    if (birthDate == null || birthDate.isEmpty) return false;
    final normalized = birthDate.contains('.')
        ? birthDate.split('.').reversed.join('-')
        : birthDate;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) return false;
    final birth = DateTime.tryParse(normalized);
    if (birth == null ||
        birth.toIso8601String().substring(0, 10) != normalized) {
      return false;
    }
    final now = today ?? DateTime.now().toUtc();
    final age =
        now.year -
        birth.year -
        ((now.month < birth.month ||
                (now.month == birth.month && now.day < birth.day))
            ? 1
            : 0);
    return age >= 18;
  }
}
