import 'package:bloc/bloc.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/complaint_submission.dart';
import 'package:disalive/domain/repositories/complaint_repository.dart';
import 'package:equatable/equatable.dart';

part 'complaint_event.dart';
part 'complaint_state.dart';

class ComplaintBloc extends Bloc<ComplaintEvent, ComplaintState> {
  ComplaintBloc(this._repository) : super(const ComplaintState()) {
    on<SubmitComplaint>(_submit);
  }

  final ComplaintRepository _repository;

  Future<void> _submit(
    SubmitComplaint event,
    Emitter<ComplaintState> emit,
  ) async {
    if (state.status == ComplaintSubmitStatus.submitting ||
        state.status == ComplaintSubmitStatus.success) {
      return;
    }
    emit(const ComplaintState(status: ComplaintSubmitStatus.submitting));
    final result = await _repository.create(event.complaint);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        ComplaintState(status: ComplaintSubmitStatus.failure, failure: failure),
      ),
      (id) => emit(
        ComplaintState(status: ComplaintSubmitStatus.success, complaintId: id),
      ),
    );
  }
}
