import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/complaint_submission.dart';

abstract interface class ComplaintRepository {
  Future<Either<Failure, int>> create(ComplaintSubmission complaint);
}
