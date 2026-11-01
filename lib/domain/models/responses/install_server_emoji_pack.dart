class InstallServerEmojiPack {
  final bool? installed;
  final int? packId;

  InstallServerEmojiPack({required this.installed, required this.packId});

  factory InstallServerEmojiPack.fromMap(Map<String, dynamic> map) {
    return InstallServerEmojiPack(
      installed: map['installed'] is bool
          ? map['installed'] as bool
          : map['installed'] is num
          ? (map['installed'] as num) != 0
          : map['installed']?.toString() == '1' ||
                map['installed']?.toString().toLowerCase() == 'true',
      packId: map['packId'] is int
          ? map['packId'] as int
          : int.tryParse(map['packId']?.toString() ?? ''),
    );
  }
}
