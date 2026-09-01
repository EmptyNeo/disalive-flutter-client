import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/presentation/utils/util_date.dart';

class ChatRepositoryImpl implements ChatRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  List<Chat>? _chats;

  @override
  Future<Either<Failure, List<Chat>>> get() async {
    final result = await _httpClient.postFormData<List<Chat>>(
      endpoint: 'chats/get.php',
      data: null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => Chat.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <Chat>[];
      },
    );

    result.fold((failure) => null, (chats) {
      chats.sort(_compareChats);
      _chats = chats;
    });

    return result;
  }

  @override
  List<Chat> getCached() {
    return _chats ?? [];
  }

  /// Порядок списка чатов:
  /// 1. Закреплённые (member.isFixed) всегда выше незакреплённых.
  /// 2. Внутри закреплённых — по member.orderFixed по возрастанию (чат с
  ///    меньшим orderFixed выше). Если у одного/обоих orderFixed не задан,
  ///    считаем его "ниже" среди закреплённых и уходим к сравнению по
  ///    времени последнего сообщения.
  /// 3. Во всех остальных случаях (незакреплённые между собой, закреплённые
  ///    с равным/отсутствующим orderFixed) — по времени последнего
  ///    сообщения по убыванию (самые свежие сверху); чаты без времени
  ///    уходят в конец.
  static int _compareChats(Chat a, Chat b) {
    final bool aPinned = a.member?.isFixed ?? false;
    final bool bPinned = b.member?.isFixed ?? false;

    if (aPinned != bPinned) {
      return aPinned ? -1 : 1;
    }

    if (aPinned && bPinned) {
      final int? aOrder = a.member?.orderFixed;
      final int? bOrder = b.member?.orderFixed;
      if (aOrder != null && bOrder != null && aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      if (aOrder != null && bOrder == null) return -1;
      if (aOrder == null && bOrder != null) return 1;
    }

    final aTime = UtilDate.parseDateTime(a.lastMessageTime);
    final bTime = UtilDate.parseDateTime(b.lastMessageTime);
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  }
}
