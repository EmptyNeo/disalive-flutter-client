// lib/presentation/features/profile/bloc/profile_event.dart
part of 'profile_bloc.dart';

@immutable
abstract class ProfileEvent {}

class GetProfile extends ProfileEvent {
  final String userResponseType;
  final String? username;

  GetProfile({required this.userResponseType, this.username});
}

class GetProfileByUsername extends ProfileEvent {
  final String username;
  final UserModel? initialUser;

  GetProfileByUsername({required this.username, this.initialUser});
}

class ClearProfile extends ProfileEvent {}

class LogoutProfile extends ProfileEvent {}

class UpdateCurrentUser extends ProfileEvent {
  final UserModel user;

  UpdateCurrentUser(this.user);
}

class UpdateProfile extends ProfileEvent {
  final UserModel updateUser;
  final String? loadingField;

  UpdateProfile(this.updateUser, {this.loadingField});
}
