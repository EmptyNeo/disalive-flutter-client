class AppUpdate {
  const AppUpdate({
    required this.isUpdateAvailable,
    required this.version,
    required this.downloadUrl,
    required this.sizeInBytes,
    required this.changelog,
    required this.about,
  });

  final bool isUpdateAvailable;
  final String version;
  final String downloadUrl;
  final int sizeInBytes;
  final String changelog;
  final String about;

  factory AppUpdate.fromMap(Map<String, dynamic> map) => AppUpdate(
    isUpdateAvailable: map['isUpdateAvailable'] == true,
    version: map['version']?.toString() ?? '',
    downloadUrl: map['downloadUrl']?.toString() ?? '',
    sizeInBytes: (map['sizeInBytes'] as num?)?.toInt() ?? 0,
    changelog: map['changelog']?.toString() ?? '',
    about: map['about']?.toString() ?? '',
  );
}
