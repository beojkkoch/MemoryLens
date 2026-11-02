import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads the usuario and usuario_interes tables.
class SupabaseProfileDataSource {
  final SupabaseClient _client = Supabase.instance.client;

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
