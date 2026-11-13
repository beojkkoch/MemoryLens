import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads the foto table.
class SupabasePhotoDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  /// The row level security of the table only lets each person see their own
  /// photos, so no filter by user is needed.
  Future<int> count() async {
    try {
      return await _client.from('foto').count(CountOption.exact);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }
}
