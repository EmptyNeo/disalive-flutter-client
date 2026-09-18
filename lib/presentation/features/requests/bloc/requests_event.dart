// lib/presentation/features/requests/bloc/requests_event.dart
part of 'requests_bloc.dart';

@immutable
abstract class RequestsEvent {}

class GetRequests extends RequestsEvent {
  final bool reload;

  GetRequests(this.reload);
}

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

// В requests_event.dart добавьте:
class AddRequest extends RequestsEvent {
  final FriendRequest request;

  AddRequest(this.request);
}

class RemoveRequest extends RequestsEvent {
  final int requestId;

  RemoveRequest(this.requestId);
}
