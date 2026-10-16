class ProfileDeepLink {
  static const String scheme = 'disalive';
  static const String host = 'profiles';

  static Uri forUsername(String username) =>
      Uri(scheme: scheme, host: host, pathSegments: [username]);

  static String? usernameFrom(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    if (uri.pathSegments.length != 1) return null;
    final username = uri.pathSegments.single;
    if (username.isEmpty || username.trim() != username) return null;
    return username;
  }
}
