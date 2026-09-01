// lib/domain/models/session.dart
import 'package:equatable/equatable.dart';

class SessionModel extends Equatable {
  final int id;
  final String createdAt;
  final bool isCurrentSession;
  final String? deviceType;
  final String? browserName;
  final String? browserVersion;
  final String? osName;
  final String? osVersion;
  final String? platform;

  const SessionModel({
    required this.id,
    required this.createdAt,
    required this.isCurrentSession,
    this.deviceType,
    this.browserName,
    this.browserVersion,
    this.osName,
    this.osVersion,
    this.platform,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'],
      createdAt: map['createdAt'],
      isCurrentSession: map['isCurrentSession'],
      deviceType: map['deviceType'],
      browserName: map['browserName'],
      browserVersion: map['browserVersion'],
      osName: map['osName'],
      osVersion: map['osVersion'],
      platform: map['platform'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt,
      'isCurrentSession': isCurrentSession,
      if (deviceType != null) 'deviceType': deviceType,
      if (browserName != null) 'browserName': browserName,
      if (browserVersion != null) 'browserVersion': browserVersion,
      if (osName != null) 'osName': osName,
      if (osVersion != null) 'osVersion': osVersion,
      if (platform != null) 'platform': platform,
    };
  }

  SessionModel copyWith({
    int? id,
    String? createdAt,
    bool? isCurrentSession,
    String? deviceType,
    String? browserName,
    String? browserVersion,
    String? osName,
    String? osVersion,
    String? platform,
  }) {
    return SessionModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      isCurrentSession: isCurrentSession ?? this.isCurrentSession,
      deviceType: deviceType ?? this.deviceType,
      browserName: browserName ?? this.browserName,
      browserVersion: browserVersion ?? this.browserVersion,
      osName: osName ?? this.osName,
      osVersion: osVersion ?? this.osVersion,
      platform: platform ?? this.platform,
    );
  }

  String get deviceInfo {
    final parts = <String>[];
    if (deviceType != null) parts.add(deviceType!);
    if (browserName != null) parts.add(browserName!);
    if (browserVersion != null) parts.add('v$browserVersion');
    if (osName != null) parts.add(osName!);
    if (osVersion != null) parts.add(osVersion!);
    return parts.isNotEmpty ? parts.join(' · ') : 'Неизвестное устройство';
  }

  String get shortDeviceInfo {
    if (deviceType != null) return deviceType!;
    if (browserName != null) return browserName!;
    if (osName != null) return osName!;
    return 'Неизвестно';
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    isCurrentSession,
    deviceType,
    browserName,
    browserVersion,
    osName,
    osVersion,
    platform,
  ];
}
