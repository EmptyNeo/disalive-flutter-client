part of 'complaint_bloc.dart';

enum ComplaintSubmitStatus { idle, submitting, success, failure }

final class ComplaintState extends Equatable {
  const ComplaintState({
    this.status = ComplaintSubmitStatus.idle,
    this.complaintId,
    this.failure,
  });

  final ComplaintSubmitStatus status;
  final int? complaintId;
  final Failure? failure;

  @override
  List<Object?> get props => [status, complaintId, failure];
}
