import 'package:memorylens/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that talks to Supabase Auth.
class SupabaseAuthDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw Exception(
          'Revisa tu correo para confirmar la cuenta antes de continuar',
        );
      }
      return _toAppUser(response.user);
    } on AuthException catch (e) {
      throw Exception(_translate(e));
    }
  }

  AppUser? currentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  AppUser _toAppUser(User? user) {
    if (user == null) throw Exception('Supabase no devolvió el usuario');
    return AppUser(id: user.id, email: user.email ?? '');
  }

  String _translate(AuthException e) {
    if (e.code == 'user_already_exists') {
      return 'Ya existe una cuenta con ese correo';
    }
    if (e.code == 'weak_password') {
      return 'La contraseña es muy débil';
    }
    if (e.code == 'email_address_invalid') {
      return 'El correo no es válido';
    }
    return e.message;
  }
}
