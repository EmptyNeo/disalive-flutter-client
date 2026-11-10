// lib/presentation/features/profile/bloc/profile_state.dart
part of 'profile_bloc.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdating extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  final Set<String> loadingFields;
  final bool saveSucceeded;

  ProfileLoaded(
    this.user, {
    this.loadingFields = const {},
    this.saveSucceeded = false,
  });

  ProfileLoaded copyWith({
    UserModel? user,
    Set<String>? loadingFields,
    bool? saveSucceeded,
  }) {
    return ProfileLoaded(
      user ?? this.user,
      loadingFields: loadingFields ?? this.loadingFields,
      saveSucceeded: saveSucceeded ?? this.saveSucceeded,
    );
  }
}

class ProfileFailure extends ProfileState {
  final Failure error;

  ProfileFailure(this.error);
}

class AuthLogoutState extends ProfileState {}
