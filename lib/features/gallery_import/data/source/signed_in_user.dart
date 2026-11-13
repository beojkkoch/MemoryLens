import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Id of the person using the app. It is read on every call, so a session that
/// ended or changed is never mixed up with the previous one.
String signedInUserId(SupabaseClient client) {
  final id = client.auth.currentUser?.id;
  if (id == null) {
    throw const AppException('Tu sesión terminó. Vuelve a iniciar sesión.');
  }
  return id;
}
