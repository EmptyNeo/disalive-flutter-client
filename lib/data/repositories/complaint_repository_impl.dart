import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/complaint_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/complaint_submission.dart';
import 'package:disalive/domain/repositories/complaint_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  const ComplaintRepositoryImpl(this._httpClient);

  final HttpClientService _httpClient;

  @override
  Future<Either<Failure, int>> create(ComplaintSubmission complaint) {
    final data = <String, dynamic>{
      'complaint_type': complaint.type.value,
      complaint.type.targetField: complaint.targetId,
      'reason': complaint.reason.trim(),
      'additional_details': complaint.details.trim(),
      'severity': complaint.severity.value,
    };
    if (complaint.type == ComplaintType.message &&
        complaint.targetChannelId != null) {
      data['target_channel'] = complaint.targetChannelId;
    }
    return _httpClient.postFormData<int>(
      endpoint: 'complaints/create',
      apiType: ApiType.v1,
      data: data,
      fromJson: (json) => (json as Map<String, dynamic>)['complaint_id'] as int,
    );
  }
}
