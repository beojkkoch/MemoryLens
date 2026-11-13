import 'package:memorylens/features/gallery_import/domain/entities/import_scan.dart';
import 'package:memorylens/features/gallery_import/domain/repository/import_scan_repository.dart';

/// Behaves like the escaneo_galeria table: a scan stays pending until its
/// import is marked as finished.
class FakeImportScanRepository implements ImportScanRepository {
  FakeImportScanRepository({List<String>? log}) : log = log ?? [];

  final List<String> log;

  /// The total saved by the last [startOrResume].
  int? savedTotal;

  final List<String> finished = [];

  bool pending = false;

  /// Thrown by [hasPendingImport] when set.
  Object? pendingError;

  @override
  Future<ImportScan> startOrResume({required int total}) async {
    log.add('scan:total=$total');
    savedTotal = total;
    pending = true;
    return const ImportScan(id: 'scan-1');
  }

  @override
  Future<void> markImportFinished(String scanId) async {
    log.add('finished:$scanId');
    finished.add(scanId);
    pending = false;
  }

  @override
  Future<bool> hasPendingImport() async {
    if (pendingError != null) throw pendingError!;
    return pending;
  }
}
