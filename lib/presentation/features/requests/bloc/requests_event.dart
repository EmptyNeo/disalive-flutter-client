part of 'requests_bloc.dart';

@immutable
abstract class RequestsEvent {}

class GetRequests extends RequestsEvent {}

class SendRequest extends RequestsEvent {
  final String username;

  SendRequest(this.username);
}

class CancelRequest extends RequestsEvent {
  final String username;

  CancelRequest(this.username);
}

class AcceptRequest extends RequestsEvent {
  final String username;

  AcceptRequest(this.username);
}