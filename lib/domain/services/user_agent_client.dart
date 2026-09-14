import 'dart:io';
import 'package:http/http.dart' as http;

class UserAgentClient extends http.BaseClient {
  final http.Client _innerClient;

  UserAgentClient(this._innerClient);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['User-Agent'] = buildUserAgent();

    request.headers['Accept'] = 'application/json';

    return _innerClient.send(request);
  }

  String buildUserAgent() {
    final os = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;

    return 'Disalive $os $osVersion';
  }

  @override
  void close() {
    _innerClient.close();
  }
}
