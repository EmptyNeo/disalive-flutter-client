import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:flutter/foundation.dart';

class DeterminingContextService {
  static EntityKey? getEntityKey() {
    try {
      //TODO: Определить сначала, есть ли выбранный сервер
      final chat = sl<ChatRepository>().getCurrentChat();
      if (chat != null) {
        return EntityKey(entityId: chat.id, entityType: EntityType.chat);
      } else {
        if (kDebugMode) {
          print("determining server");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("sl is not defined: ${e.toString()}");
      }
    }
    return null;
  }
}
