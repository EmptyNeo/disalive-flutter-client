import 'package:equatable/equatable.dart';

class ReactionSummary extends Equatable {
  final int cursor;
  final String nameReaction;
  final int amount;

  const ReactionSummary({
    required this.cursor,
    required this.nameReaction,
    required this.amount,
  });

  factory ReactionSummary.fromMap(Map<String, dynamic> map) => ReactionSummary(
    cursor: _asInt(map['cursor']),
    nameReaction: map['nameReaction']?.toString() ?? '',
    amount: _asInt(map['amount']),
  );

  @override
  List<Object?> get props => [cursor, nameReaction, amount];
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
