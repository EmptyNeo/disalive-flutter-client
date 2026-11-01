import 'package:equatable/equatable.dart';

class EntityAccess extends Equatable {
  final bool banned;
  final String? banReason;
  final String? banExpiresAt;

  const EntityAccess({this.banned = false, this.banReason, this.banExpiresAt});

  factory EntityAccess.fromMap(Map<String, dynamic> map) {
    final ban = map['ban'] is Map
        ? Map<String, dynamic>.from(map['ban'] as Map)
        : const <String, dynamic>{};
    return EntityAccess(
      banned: _asBool(map['banned']) || ban.isNotEmpty,
      banReason: (ban['reason'] ?? map['banReason']) as String?,
      banExpiresAt: (ban['expiresAt'] ?? map['banExpiresAt']) as String?,
    );
  }

  @override
  List<Object?> get props => [banned, banReason, banExpiresAt];
}

bool _asBool(Object? value) =>
    value == true || value == 1 || value == '1' || value == 'true';
