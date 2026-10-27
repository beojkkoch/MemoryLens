import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads and writes the interes catalog.
class SupabaseInterestDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Interest>> getInterests() async {
    try {
      final rows = await _client
          .from('interes')
          .select()
          .order('id', ascending: true);
      return rows.map(_toInterest).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Inserts the names that are not in the catalog yet and returns all of them
  /// with their id, so a name someone else just added is reused.
  Future<List<Interest>> createInterests(List<String> names) async {
    try {
      await _client
          .from('interes')
          .upsert(
            [
              for (final name in names) {'nombre': name},
            ],
            onConflict: 'nombre',
            ignoreDuplicates: true,
          );
      final rows = await _client
          .from('interes')
          .select()
          .inFilter('nombre', names);
      return rows.map(_toInterest).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Interest _toInterest(Map<String, dynamic> row) {
    return Interest(id: row['id'] as int, name: row['nombre'] as String);
  }
}
