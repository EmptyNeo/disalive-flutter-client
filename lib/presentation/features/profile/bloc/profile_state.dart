// lib/presentation/features/profile/bloc/profile_state.dart
part of 'profile_bloc.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;

  ProfileLoaded(this.user);
}

class ProfileFailure extends ProfileState {
  final String error;

  ProfileFailure(this.error);
}