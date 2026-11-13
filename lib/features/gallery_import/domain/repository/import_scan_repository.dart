import 'package:memorylens/features/gallery_import/domain/entities/import_scan.dart';

/// Keeps the scan of the gallery: how many photos have to be processed and
/// whether their import is over.
abstract class ImportScanRepository {
  /// Continues the scan left open, or starts a new one, and saves [total] as
  /// the number of photos to process.
  Future<ImportScan> startOrResume({required int total});

  /// Marks the import of the scan as over.
  Future<void> markImportFinished(String scanId);

  /// Whether a scan was started and its import never finished.
  Future<bool> hasPendingImport();
}
