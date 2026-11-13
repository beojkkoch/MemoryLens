/// How far an import has got.
class ImportProgress {
  /// Photos found on the device.
  final int total;

  /// Photos already in the person's storage, including the ones imported in
  /// an earlier run.
  final int imported;

  /// Photos that could not be read (deleted meanwhile, not downloaded from the
  /// cloud) and were left out.
  final int skipped;

  const ImportProgress({
    required this.total,
    required this.imported,
    required this.skipped,
  });

  @override
  String toString() =>
      'ImportProgress(total: $total, imported: $imported, skipped: $skipped)';
}
