import 'package:memorylens/features/auth/domain/entities/interest.dart';
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

  Future<Profile> getProfile(String id) async {
    try {
      final row = await _client
          .from('usuario')
          .select('*, usuario_interes(interes(id, nombre))')
          .eq('id', id)
          .single();
      final links = (row['usuario_interes'] as List?) ?? const [];
      return Profile(
        id: row['id'],
        fullName: row['nombre'],
        email: row['correo'],
        city: row['ciudad'],
        profession: row['profesion'],
        interests: [
          for (final link in links)
            Interest(
              id: link['interes']['id'],
              name: link['interes']['nombre'],
            ),
        ],
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
