import 'package:memorylens/features/gallery_import/data/source/supabase_import_scan_data_source.dart';
import 'package:memorylens/features/gallery_import/domain/entities/import_scan.dart';
import 'package:memorylens/features/gallery_import/domain/repository/import_scan_repository.dart';
import 'package:memorylens/injection_container.dart';

class ImportScanRepositoryImpl implements ImportScanRepository {
  final SupabaseImportScanDataSource _dataSource = sl();

  @override
  Future<ImportScan> startOrResume({required int total}) async {
    final id = await _dataSource.startOrResume(total: total);
    return ImportScan(id: id);
  }

  @override
  Future<void> markImportFinished(String scanId) {
    return _dataSource.markImportFinished(scanId);
  }

  @override
  Future<bool> hasPendingImport() {
    return _dataSource.hasPendingImport();
  }
}
