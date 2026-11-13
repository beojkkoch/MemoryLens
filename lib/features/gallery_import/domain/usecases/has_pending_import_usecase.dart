import 'package:memorylens/features/gallery_import/domain/repository/import_scan_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Tells whether an import was left half done, for example because the app
/// was closed in the middle of it.
class HasPendingImportUseCase {
  final ImportScanRepository _scans = sl();

  Future<bool> call() {
    return _scans.hasPendingImport();
  }
}
