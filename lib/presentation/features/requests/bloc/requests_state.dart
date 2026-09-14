part of 'requests_bloc.dart';

@immutable
abstract class RequestsState {}

class RequestsInitial extends RequestsState {}

class RequestsLoading extends RequestsState {}

class RequestsLoaded extends RequestsState {
  final List<FriendRequest> requests;

  RequestsLoaded(this.requests);
}

class RequestsFailure extends RequestsState {
  final Failure error;

  RequestsFailure(this.error);
}