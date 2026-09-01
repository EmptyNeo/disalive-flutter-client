// lib/presentation/features/profile/bloc/profile_event.dart
part of 'profile_bloc.dart';

@immutable
abstract class ProfileEvent {}

class GetProfile extends ProfileEvent {
  final String userResponseType;
  final String? username;

  GetProfile({required this.userResponseType, this.username});
}

class ClearProfile extends ProfileEvent {}

class LogoutProfile extends ProfileEvent {}
