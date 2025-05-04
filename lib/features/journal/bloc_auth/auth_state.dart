part of 'auth_bloc.dart'; // AuthBloc dosyasına bağlanacak

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthInProgress extends AuthState {}

class AuthLocked extends AuthState {
  final bool biometricsEnabled;
  final bool canCheckBiometrics;
  const AuthLocked({
    this.biometricsEnabled = false,
    this.canCheckBiometrics = false,
  });
  @override
  List<Object?> get props => [biometricsEnabled, canCheckBiometrics];
}

class AuthUnlocked extends AuthState {}

class AuthSetupRequired extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}