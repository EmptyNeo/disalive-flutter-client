import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:disalive/domain/enums/file_content_type.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDraft {
  final String text;
  final List<ChatAttachment> attachments;
  final List<ChatAttachment> deletedAttachments;
  final Message? answerMessage;
  final int? editingMessageId;

  const ChatDraft({
    this.text = '',
    this.attachments = const [],
    this.deletedAttachments = const [],
    this.answerMessage,
    this.editingMessageId,
  });

  bool get isEmpty =>
      text.trim().isEmpty &&
      attachments.isEmpty &&
      deletedAttachments.isEmpty &&
      answerMessage == null &&
      editingMessageId == null;

  Map<String, dynamic> toMap() => {
    'text': text,
    'attachments': attachments.map(_attachmentToMap).toList(),
    'deletedAttachments': deletedAttachments.map(_attachmentToMap).toList(),
    if (answerMessage != null)
      'answerMessage': {
        'id': answerMessage!.id,
        'text': answerMessage!.text,
        if (answerMessage!.user != null)
          'user': {
            'id': answerMessage!.user!.id,
            'displayName': answerMessage!.user!.displayName,
          },
      },
    if (editingMessageId != null) 'editingMessageId': editingMessageId,
  };

  factory ChatDraft.fromMap(Map<String, dynamic> map) => ChatDraft(
    text: map['text'] as String? ?? '',
    attachments: _attachmentsFromMap(map['attachments']),
    deletedAttachments: _attachmentsFromMap(map['deletedAttachments']),
    answerMessage: map['answerMessage'] is Map
        ? Message.fromMap(
            Map<String, dynamic>.from(map['answerMessage'] as Map),
          )
        : null,
    editingMessageId: map['editingMessageId'] as int?,
  );

  static Map<String, dynamic> _attachmentToMap(ChatAttachment attachment) => {
    'id': attachment.id,
    'path': attachment.file?.path,
    'url': attachment.url,
    'name': attachment.name,
    'size': attachment.size,
    'unit': attachment.unit,
    'fileType': attachment.fileType.value,
    'contentType': attachment.contentType.value,
    'duration': attachment.duration,
    'isSpoiler': attachment.isSpoiler,
    'isDeleted': attachment.isDeleted,
  };

  static List<ChatAttachment> _attachmentsFromMap(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((raw) {
      final map = Map<String, dynamic>.from(raw);
      final path = map['path'] as String?;
      return ChatAttachment(
        id: map['id'] as int?,
        file: path == null ? null : File(path),
        url: map['url'] as String?,
        name: map['name'] as String? ?? '',
        size: (map['size'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] as String? ?? 'Б',
        fileType: FileType.values.firstWhere(
          (type) => type.value == map['fileType'],
          orElse: () => FileType.file,
        ),
        contentType: FileContentType.fromString(map['contentType'] as String?),
        duration: (map['duration'] as num?)?.toDouble(),
        isSpoiler: map['isSpoiler'] == true,
        isDeleted: map['isDeleted'] == true,
      );
    }).toList();
  }
}

class LocalChatStateRepository {
  LocalChatStateRepository(
    this._preferences, {
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final SharedPreferences _preferences;
  final Future<Directory> Function() _directoryProvider;
  final ValueNotifier<int> revision = ValueNotifier(0);
  final Map<String, Future<void>> _pending = {};
  final Map<String, ChatDraft?> _latest = {};
  final Map<String, int> _positions = {};
  final Set<int> _clearedUsers = {};
  bool _notificationPending = false;

  String _key(int? userId, int chatId, String kind) =>
      'chat_${userId ?? 0}_${chatId}_$kind';

  ChatDraft? getDraft(int? userId, int chatId) {
    if (_clearedUsers.contains(userId ?? 0)) return null;
    final key = _key(userId, chatId, 'draft');
    if (_latest.containsKey(key)) return _latest[key];
    final raw = _preferences.getString(key);
    if (raw == null) return null;
    try {
      final draft = ChatDraft.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      return ChatDraft(
        text: draft.text,
        attachments: draft.attachments
            .where(
              (attachment) =>
                  attachment.file == null || attachment.file!.existsSync(),
            )
            .toList(),
        deletedAttachments: draft.deletedAttachments,
        answerMessage: draft.answerMessage,
        editingMessageId: draft.editingMessageId,
      );
    } catch (_) {
      return null;
    }
  }

  int? getFirstVisibleMessageId(int? userId, int chatId) {
    final key = _key(userId, chatId, 'position');
    return _positions[key] ?? _preferences.getInt(key);
  }

  Future<void> saveFirstVisibleMessageId(
    int? userId,
    int chatId,
    int messageId,
  ) {
    final key = _key(userId, chatId, 'position');
    _positions[key] = messageId;
    return _preferences.setInt(key, messageId);
  }

  Future<void> saveDraft(int? userId, int chatId, ChatDraft draft) {
    if (_clearedUsers.contains(userId ?? 0)) return Future<void>.value();
    final key = _key(userId, chatId, 'draft');
    _latest[key] = draft.isEmpty ? null : draft;
    _notifyDraftChanged();
    final previous = _pending[key] ?? Future<void>.value();
    final next = previous.catchError((Object _) {}).then((_) async {
      if (draft.isEmpty) {
        await _preferences.remove(key);
      } else {
        final persisted = await _copyFiles(userId, chatId, draft);
        await _preferences.setString(key, jsonEncode(persisted.toMap()));
        if (identical(_latest[key], draft)) _latest[key] = persisted;
      }
    });
    _pending[key] = next;
    return next;
  }

  Future<void> clearDraftsForUser(int? userId) async {
    final id = userId ?? 0;
    final prefix = 'chat_${id}_';
    _clearedUsers.add(id);

    await Future.wait([
      for (final entry in _pending.entries)
        if (entry.key.startsWith(prefix) && entry.key.endsWith('_draft'))
          entry.value.catchError((Object _) {}),
    ]);

    final keys = {
      ..._preferences.getKeys(),
      ..._latest.keys,
    }.where((key) => key.startsWith(prefix) && key.endsWith('_draft'));
    for (final key in keys) {
      await _preferences.remove(key);
      _latest.remove(key);
      _pending.remove(key);
    }

    final root = await _directoryProvider();
    final folder = Directory(p.join(root.path, 'chat_drafts', '$id'));
    if (await folder.exists()) await folder.delete(recursive: true);
    _notifyDraftChanged();
  }

  void allowDraftsForUser(int? userId) {
    _clearedUsers.remove(userId ?? 0);
  }

  void _notifyDraftChanged() {
    if (_notificationPending) return;
    _notificationPending = true;
    scheduleMicrotask(() {
      _notificationPending = false;
      revision.value++;
    });
  }

  Future<ChatDraft> _copyFiles(int? userId, int chatId, ChatDraft draft) async {
    if (![
      ...draft.attachments,
      ...draft.deletedAttachments,
    ].any((attachment) => attachment.file != null)) {
      return draft;
    }
    final root = await _directoryProvider();
    final folder = Directory(
      p.join(root.path, 'chat_drafts', '${userId ?? 0}', '$chatId'),
    );
    await folder.create(recursive: true);

    Future<List<ChatAttachment>> copy(List<ChatAttachment> source) async {
      final result = <ChatAttachment>[];
      for (final attachment in source) {
        final file = attachment.file;
        if (file == null) {
          result.add(attachment);
          continue;
        }
        if (!await file.exists()) continue;
        final target = p.isWithin(folder.path, file.path)
            ? file.path
            : p.join(
                folder.path,
                '${file.path.hashCode.toUnsigned(32)}_${p.basename(file.path)}',
              );
        if (file.path != target && !await File(target).exists()) {
          await file.copy(target);
        }
        result.add(
          ChatAttachment(
            id: attachment.id,
            file: File(target),
            url: attachment.url,
            name: attachment.name,
            size: attachment.size,
            unit: attachment.unit,
            fileType: attachment.fileType,
            contentType: attachment.contentType,
            duration: attachment.duration,
            isSpoiler: attachment.isSpoiler,
            isDeleted: attachment.isDeleted,
          ),
        );
      }
      return result;
    }

    return ChatDraft(
      text: draft.text,
      attachments: await copy(draft.attachments),
      deletedAttachments: await copy(draft.deletedAttachments),
      answerMessage: draft.answerMessage,
      editingMessageId: draft.editingMessageId,
    );
  }
}
