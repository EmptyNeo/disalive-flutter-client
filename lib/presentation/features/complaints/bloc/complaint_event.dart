part of 'complaint_bloc.dart';

sealed class ComplaintEvent extends Equatable {
  const ComplaintEvent();
}

final class SubmitComplaint extends ComplaintEvent {
  const SubmitComplaint(this.complaint);

  final ComplaintSubmission complaint;

  @override
  List<Object?> get props => [complaint];
}
