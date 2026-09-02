// lib/presentation/utils/id_generator.dart
import 'dart:math';

class IdGenerator {
  IdGenerator._();

  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}