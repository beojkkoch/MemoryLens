import 'package:flutter/foundation.dart';
import 'package:memorylens/features/error_handling/data/mapper/error_report_row.dart';
import 'package:memorylens/features/error_handling/domain/entities/error_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that writes in the registro_error table.
class SupabaseErrorLogDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> insert(ErrorReport report) async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    await _client
        .from('registro_error')
        .insert(errorReportToRow(report, platform: platform));
  }
}
