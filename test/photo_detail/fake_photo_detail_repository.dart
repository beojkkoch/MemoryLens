import 'dart:async';

import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';
import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';

/// Serves the photos the backend would have. A photo not in [details] is
/// one that does not exist or is someone else's.
class FakePhotoDetailRepository implements PhotoDetailRepository {
  final Map<String, PhotoDetail> details = {};

  /// When true, any id not in [details] is a photo titled «Foto» and the id.
  bool answerEveryId = false;

  /// The catalog of the system.
  List<String> categoryNames = const [
    'Factura',
    'Comida',
    'Lugar',
    'Viaje',
    'Mascotas',
    'Personas',
    'Arte',
    'Trabajo',
  ];

  /// Thrown by [find] when set.
  Object? error;

  /// Thrown by [save] when set.
  Object? saveError;

  /// When set, [save] waits for it.
  Completer<void>? saveGate;

  final List<String> asked = [];

  /// Every save, as (photo id, edit).
  final List<(String, PhotoEdit)> saved = [];

  @override
  Future<PhotoDetail?> find(String id) async {
    asked.add(id);
    if (error != null) throw error!;
    return details[id] ??
        (answerEveryId ? PhotoDetail(id: id, title: 'Foto $id') : null);
  }

  @override
  Future<List<String>> categories() async {
    if (error != null) throw error!;
    return categoryNames;
  }

  /// Keeps the corrections, so opening the photo again shows them.
  @override
  Future<void> save(String id, PhotoEdit edit) async {
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    saved.add((id, edit));
    final before = details[id];
    if (before == null) return;
    details[id] = PhotoDetail(
      id: id,
      imageUrl: before.imageUrl,
      title: before.title,
      description: before.description,
      takenAt: before.takenAt,
      category: edit.category,
      purchaseType: edit.purchaseType,
      total: edit.total,
    );
  }
}
