import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that writes the usuario and usuario_interes tables.
class SupabaseProfileDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createProfile(Profile profile) async {
    try {
      await _client.from('usuario').insert({
        'id': profile.id,
        'nombre': profile.fullName,
        'correo': profile.email,
        'ciudad': profile.city,
        'profesion': profile.profession,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> saveInterests(String userId, List<int> interestIds) async {
    if (interestIds.isEmpty) return;
    try {
      await _client.from('usuario_interes').insert([
        for (final id in interestIds) {'usuario_id': userId, 'interes_id': id},
      ]);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
