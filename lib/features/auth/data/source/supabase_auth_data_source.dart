import 'package:flutter/foundation.dart';
import 'package:memorylens/features/auth/domain/entities/app_user.dart';
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that talks to Supabase Auth.
class SupabaseAuthDataSource {
  static const _webRedirectUrl = 'http://localhost:3000/';
  static const _mobileRedirectUrl = 'memorylens://login-callback/';

  /// Auth error codes the person can fix, with the text to show.
  static const _messages = {
    'user_already_exists': 'Ya existe una cuenta con ese correo',
    'weak_password': 'La contraseña es muy débil',
    'email_address_invalid': 'El correo no es válido',
    'invalid_credentials': 'Correo o contraseña incorrectos',
    'invalid_login_credentials': 'Correo o contraseña incorrectos',
    'email_not_confirmed': 'Confirma tu correo antes de iniciar sesión',
    'invalid_password': 'Contraseña incorrecta',
  };

  final SupabaseClient _client = Supabase.instance.client;

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String city,
    required String profession,
    required List<int> interestIds,
    required List<String> newInterestNames,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb ? _webRedirectUrl : _mobileRedirectUrl,
        data: {
          'nombre': fullName,
          'ciudad': city,
          'profesion': profession,
          'intereses': interestIds,
          'intereses_nuevos': newInterestNames,
        },
      );
      // With confirmations on, Supabase hides that the email is taken and
      // answers with a user that has no identities.
      if (response.user?.identities?.isEmpty ?? false) {
        throw const AppException('Ya existe una cuenta con ese correo');
      }
      return _toAppUser(response.user);
    } on AuthException catch (e, stack) {
      Error.throwWithStackTrace(_translate(e), stack);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AppException(
          'No pudimos iniciar tu sesión. Inténtalo de nuevo.',
          kind: AppErrorKind.server,
        );
      }
      return _toAppUser(response.user);
    } on AuthException catch (e, stack) {
      Error.throwWithStackTrace(_translate(e), stack);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  AppUser? currentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  AppUser _toAppUser(User? user) {
    if (user == null) {
      throw const AppException(
        AppException.genericMessage,
        kind: AppErrorKind.server,
      );
    }
    return AppUser(id: user.id, email: user.email ?? '');
  }

  /// Known codes get their own message; anything else is a technical failure.
  AppException _translate(AuthException e) {
    final message = _messages[e.code];
    if (message == null) return ExceptionMapper.map(e);
    return AppException(message, cause: e);
  }
}
