class UtilFile {
  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    }
    return '$bytes Б';
  }
}
