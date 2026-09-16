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

  ProfileLoaded(this.user, {this.loadingFields = const {}});

  ProfileLoaded copyWith({UserModel? user, Set<String>? loadingFields}) {
    return ProfileLoaded(
      user ?? this.user,
      loadingFields: loadingFields ?? this.loadingFields,
    );
  }
}

class ProfileFailure extends ProfileState {
  final Failure error;

  ProfileFailure(this.error);
}

class AuthLogoutState extends ProfileState {}
