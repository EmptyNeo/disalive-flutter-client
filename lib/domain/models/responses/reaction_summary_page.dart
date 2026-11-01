import 'package:disalive/domain/models/reaction_summary.dart';
import 'package:equatable/equatable.dart';

class ReactionSummaryPage extends Equatable {
  final List<ReactionSummary> items;
  final int? nextCursor;
  final bool hasMore;

  const ReactionSummaryPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  factory ReactionSummaryPage.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    if (rawItems is! List) {
      throw const FormatException('В ответе reactions нет списка items');
    }

    return ReactionSummaryPage(
      items: rawItems
          .map((item) {
            if (item is! Map) {
              throw const FormatException('Элемент items не является объектом');
            }
            return ReactionSummary.fromMap(Map<String, dynamic>.from(item));
          })
          .toList(growable: false),
      nextCursor: _asNullableInt(map['nextCursor']),
      hasMore: _asBool(map['hasMore']),
    );
  }

  factory ReactionSummaryPage.fromResponse(Object? response) {
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      if (map['success'] == true && map['items'] == null) {
        return const ReactionSummaryPage(
          items: [],
          nextCursor: null,
          hasMore: false,
        );
      }
      return ReactionSummaryPage.fromMap(map);
    }
    throw const FormatException('Ожидался объект страницы с полем items');
  }

  @override
  List<Object?> get props => [items, nextCursor, hasMore];
}

int? _asNullableInt(Object? value) => value == null
    ? null
    : value is num
    ? value.toInt()
    : int.tryParse(value.toString());

bool _asBool(Object? value) =>
    value == true || value == 1 || value == '1' || value == 'true';
