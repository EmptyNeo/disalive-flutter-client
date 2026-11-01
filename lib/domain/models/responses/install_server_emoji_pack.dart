class InstallServerEmojiPack {
  final bool? installed;
  final int? packId;

  InstallServerEmojiPack({required this.installed, required this.packId});

  factory InstallServerEmojiPack.fromMap(Map<String, dynamic> map) {
    return InstallServerEmojiPack(
      installed: map['installed'],
      packId: map['packId'],
    );
  }
}
