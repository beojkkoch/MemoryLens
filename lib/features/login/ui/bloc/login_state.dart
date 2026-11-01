enum LoginStatus { initial, loading, success, failure }

/// Single state of the login screen; status says which moment it is.
class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({this.status = LoginStatus.initial, this.errorMessage});

  /// errorMessage is not carried over: every copy clears it unless given.
  LoginState copyWith({LoginStatus? status, String? errorMessage}) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'LoginState(status: ${status.name}, error: $errorMessage)';
  }
}
