import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that asks buscar_fotos_por_palabras which photos match some
/// words. It is the provisional search: the semantic one (HU-21) replaces it.
class SupabasePhotoSearchDataSource {
  /// The same limit the function applies (HU-21, CA4).
  static const maxPhotos = 12;

  /// At most this many words of a question are used.
  static const maxTerms = 8;

  /// Words that are in almost every question and say nothing about the photo.
  static const _stopWords = {
    'donde',
    'esta',
    'estan',
    'que',
    'una',
    'uno',
    'unas',
    'unos',
    'del',
    'los',
    'las',
    'por',
    'con',
    'para',
    'como',
    'mis',
    'mas',
    'muy',
    'hay',
    'foto',
    'fotos',
    'imagen',
    'imagenes',
    'tengo',
    'tomo',
    'saque',
    'busca',
    'buscar',
    'muestrame',
    'quiero',
    'ver',
    'cuando',
    'cual',
    'cuales',
  };

  final SupabaseClient _client = Supabase.instance.client;

  /// Ids of the photos of the person, the ones that match more words first.
  /// The row level security keeps other people's photos out.
  Future<List<String>> photoIds(List<String> terms) async {
    try {
      final rows = await _client.rpc(
        'buscar_fotos_por_palabras',
        params: {'p_palabras': terms, 'p_limite': maxPhotos},
      );
      return [for (final row in rows as List) (row as Map)['id'] as String];
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// The words of a question that are worth searching: lowercase, with no
  /// accents or signs, at least 3 letters, no repeats and not the filler of a
  /// question («¿dónde está la factura del café?» gives factura and cafe).
  static List<String> termsFrom(String question) {
    final words = _plain(
      question,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').split(' ');
    final terms = <String>[];
    for (final word in words) {
      if (word.length < 3 || _stopWords.contains(word)) continue;
      if (!terms.contains(word)) terms.add(word);
    }
    return terms.take(maxTerms).toList();
  }

  static String _plain(String text) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    var result = text.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }
}
