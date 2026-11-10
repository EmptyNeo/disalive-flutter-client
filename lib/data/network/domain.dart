class Domain {
  static const String baseUrl = 'https://disalive.ru/php/';
  static const String api = 'https://disalive.ru/v1/';
  static const String imageBasePath = '/var/www/VoiceHub/';
  static const String imageDomain = 'https://disalive.ru/';

  static String transformUrl(String? path) {
    if (path == null) return '';
    if (path.startsWith(Domain.imageBasePath)) {
      return path.replaceFirst(Domain.imageBasePath, Domain.imageDomain);
    }
    return path;
  }

  static String resolveImageUrl(String path) {
    final transformed = transformUrl(path);
    final uri = Uri.tryParse(transformed);
    if (uri == null || transformed.isEmpty) return '';
    if (uri.hasScheme) return transformed;
    return Uri.parse(imageDomain).resolve(transformed).toString();
  }
}
