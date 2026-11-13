import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
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
      return rows.map(_toInterest).toList();
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Interest _toInterest(Map<String, dynamic> row) {
    return Interest(id: row['id'] as int, name: row['nombre'] as String);
  }
}
