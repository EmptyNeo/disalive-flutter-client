/// Координата конкретного вложения: индекс сообщения в том же списке
/// [Message], которым уже пользуется MessageBloc/MessagesList, и индекс
/// вложения внутри message.attachments.
class MediaPosition {
  const MediaPosition({
    required this.messageId,
    required this.attachmentIndex,
  });

  final int? messageId;
  final int attachmentIndex;

  @override
  bool operator ==(Object other) =>
      other is MediaPosition &&
          other.messageId == messageId &&
          other.attachmentIndex == attachmentIndex;

  @override
  int get hashCode => Object.hash(messageId, attachmentIndex);
}