part of 'auth_bloc.dart'; // AuthBloc dosyasına bağlanacak

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class UnlockWithPin extends AuthEvent {
  final String pin;
  const UnlockWithPin(this.pin);
  @override List<Object?> get props => [pin];
}

class UnlockWithBiometrics extends AuthEvent {}

class SetupPin extends AuthEvent {
  final String newPin;
  const SetupPin(this.newPin);
  @override List<Object?> get props => [newPin];
}

class RemovePin extends AuthEvent {}

class ToggleBiometrics extends AuthEvent {
  final bool enable;
  const ToggleBiometrics(this.enable);
  @override List<Object?> get props => [enable];
}

class LockApp extends AuthEvent {}