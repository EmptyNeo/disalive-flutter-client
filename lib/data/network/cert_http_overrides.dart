import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class CertHttpOverrides extends HttpOverrides {
  final SecurityContext context;

  CertHttpOverrides(this.context);

  @override
  HttpClient createHttpClient(SecurityContext? _) {
    return super.createHttpClient(context);
  }

  // Статический метод можно вызвать без создания экземпляра класса
  static Future<void> init() async {
    final ByteData certData = await rootBundle.load(
      'assets/certs/globalsign.pem',
    );

    final SecurityContext securityContext = SecurityContext(
      withTrustedRoots: true,
    );

    securityContext.setTrustedCertificatesBytes(certData.buffer.asUint8List());

    HttpOverrides.global = CertHttpOverrides(securityContext);
  }
}