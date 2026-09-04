// lib/domain/enums/request_type.dart
enum RequestType {
  outgoing('outgoing'),
  incoming('incoming');

  final String value;

  const RequestType(this.value);

  static RequestType fromString(String? value) {
    if (value == null) return RequestType.incoming;
    for (final type in RequestType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return RequestType.incoming;
  }
}
