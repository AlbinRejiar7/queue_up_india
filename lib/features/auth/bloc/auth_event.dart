import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class AuthGooglePressed extends AuthEvent {
  const AuthGooglePressed();
}

class AuthResetRequested extends AuthEvent {
  const AuthResetRequested();
}
