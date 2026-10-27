import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads the interes catalog.
class SupabaseInterestDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Interest>> getInterests() async {
    try {
      final rows = await _client
          .from('interes')
          .select()
          .order('id', ascending: true);
      return rows
          .map(
            (row) =>
                Interest(id: row['id'] as int, name: row['nombre'] as String),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
