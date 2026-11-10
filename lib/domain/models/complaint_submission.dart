import 'package:disalive/domain/enums/complaint_severity.dart';
import 'package:disalive/domain/enums/complaint_type.dart';

class ComplaintSubmission {
  const ComplaintSubmission({
    required this.type,
    required this.targetId,
    required this.reason,
    this.details = '',
    this.severity = ComplaintSeverity.medium,
    this.targetChannelId,
  });

  final ComplaintType type;
  final int targetId;
  final String reason;
  final String details;
  final ComplaintSeverity severity;
  final int? targetChannelId;
}
