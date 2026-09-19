// lib/domain/models/ui/meta_file_message.dart

class MetaFileMessage {
  final int? id;
  final int? index;
  final double? duration;
  final bool? isSpoiler;
  final bool? deleted;
  final bool? changed;

  MetaFileMessage({
    this.id,
    this.index,
    this.duration,
    this.isSpoiler,
    this.deleted,
    this.changed,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (index != null) 'index': index,
      if (duration != null) 'duration': duration,
      if (isSpoiler != null) 'isSpoiler': isSpoiler,
      if (deleted != null) 'deleted': deleted,
      if (changed != null) 'changed': changed,
    };
  }
}