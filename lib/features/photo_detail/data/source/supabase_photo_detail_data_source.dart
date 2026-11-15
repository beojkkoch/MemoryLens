import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads one photo with its analysis for the detail and
/// saves the corrections of the person.
class SupabasePhotoDetailDataSource {
  static const bucket = 'fotos';

  /// How long the link to the large image works. Opening the photo again
  /// signs a new one.
  static const signedUrlLifetime = Duration(hours: 1);

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final SupabaseClient _client = Supabase.instance.client;

  /// The row level security hides the photos of other people, so a photo
  /// that is not the person's reads as missing.
  Future<PhotoDetail?> find(String id) async {
    // Postgres rejects an id that is not a uuid; for the person it is just
    // a photo that does not exist.
    if (!_uuid.hasMatch(id)) return null;
    try {
      final row = await _client
          .from('foto')
          .select(
            'id, url_imagen, titulo, texto_alt, fecha_captura, tipo_compra, '
            'monto, moneda, categoria(nombre)',
          )
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return detailFrom(row, imageUrl: await _sign(row['url_imagen']));
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// In the order of the catalog.
  Future<List<String>> categories() async {
    try {
      final rows = await _client.from('categoria').select('nombre').order('id');
      return [for (final row in rows) row['nombre'] as String];
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// guardar_correccion_foto checks the data again, updates the tags and
  /// clears the purchase data outside «Factura».
  Future<void> save(String id, PhotoEdit edit) async {
    try {
      await _client.rpc('guardar_correccion_foto', params: paramsFor(id, edit));
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  static Map<String, dynamic> paramsFor(String id, PhotoEdit edit) {
    return {
      'p_foto_id': id,
      'p_categoria': edit.category,
      'p_tipo_compra': edit.purchaseType,
      'p_monto': edit.total?.amount,
      'p_moneda': edit.total?.currency,
    };
  }

  /// A missing file is not a missing photo: the data still shows, with a
  /// gray box in place of the image.
  Future<String?> _sign(Object? path) async {
    if (path is! String) return null;
    try {
      return await _client.storage
          .from(bucket)
          .createSignedUrl(path, signedUrlLifetime.inSeconds);
    } on StorageException {
      return null;
    }
  }

  /// Reads a row of foto with its category embedded.
  static PhotoDetail detailFrom(Map<String, dynamic> row, {String? imageUrl}) {
    final category = row['categoria'];
    final amount = row['monto'];
    final currency = row['moneda'];
    final takenAt = row['fecha_captura'];
    return PhotoDetail(
      id: row['id'] as String,
      imageUrl: imageUrl,
      title: _text(row['titulo']),
      description: _text(row['texto_alt']),
      takenAt: takenAt is String ? DateTime.tryParse(takenAt)?.toLocal() : null,
      category: category is Map ? _text(category['nombre']) : null,
      purchaseType: _text(row['tipo_compra']),
      total: amount is num && currency is String
          ? Money(amount: amount.toDouble(), currency: currency)
          : null,
    );
  }

  static String? _text(Object? value) {
    final text = value is String ? value.trim() : null;
    return text == null || text.isEmpty ? null : text;
  }
}
