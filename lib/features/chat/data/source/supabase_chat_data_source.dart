import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/memories/data/source/supabase_photo_data_source.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads and writes the conversaciones, mensajes and the
/// photos of each answer (resultado_mensaje).
class SupabaseChatDataSource {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final SupabaseClient _client = Supabase.instance.client;

  /// Signs the thumbnails of the photos of the answers.
  final SupabasePhotoDataSource _photos = sl();

  /// The row level security only lets each person see their own
  /// conversations, so no filter by user is needed (HU-25, CA3).
  Future<List<Conversation>> conversations() async {
    try {
      final rows = await _client
          .from('conversacion')
          .select('id, titulo, actualizada_en')
          .order('actualizada_en', ascending: false)
          .order('id');
      return [for (final row in rows) conversationFrom(row)];
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// The messages of a conversation with the photos of each answer. The
  /// photos are signed in one call for the whole conversation.
  Future<List<ChatMessage>> messages(String conversationId) async {
    // A conversation that was never saved has no messages, and Postgres
    // rejects an id that is not a uuid.
    if (!_uuid.hasMatch(conversationId)) return const [];
    try {
      final rows = await _client
          .from('mensaje')
          .select(
            'id, rol, texto, creado_en, resultado_mensaje(foto_id, posicion)',
          )
          .eq('conversacion_id', conversationId)
          .order('creado_en')
          .order('id');
      final ids = {
        for (final row in rows)
          for (final id in photoIdsFrom(row)) id,
      };
      final photos = {
        for (final photo in await _photos.byIds(ids.toList())) photo.id: photo,
      };
      return [for (final row in rows) messageFrom(row, photos)];
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// guardar_mensaje_chat creates the conversation with the first message,
  /// saves the photos in order and moves its last activity.
  Future<void> saveMessage(
    String conversationId,
    ChatMessage message, {
    String? title,
  }) async {
    try {
      await _client.rpc(
        'guardar_mensaje_chat',
        params: paramsFor(conversationId, message, title: title),
      );
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// The messages and results go with it (cascade); the photos stay.
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _client.from('conversacion').delete().eq('id', conversationId);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  static Map<String, dynamic> paramsFor(
    String conversationId,
    ChatMessage message, {
    String? title,
  }) {
    return {
      'p_conversacion_id': conversationId,
      'p_titulo': title,
      'p_rol': message.role.name,
      'p_texto': message.text,
      'p_fotos': [for (final photo in message.photos) photo.id],
    };
  }

  static Conversation conversationFrom(Map<String, dynamic> row) {
    final updatedAt = row['actualizada_en'];
    return Conversation(
      id: row['id'] as String,
      title: row['titulo'] as String,
      updatedAt: updatedAt is String
          ? DateTime.tryParse(updatedAt)?.toLocal()
          : null,
    );
  }

  /// The ids of the photos of an answer, in the order it shows them.
  static List<String> photoIdsFrom(Map<String, dynamic> row) {
    final results = [
      for (final result in (row['resultado_mensaje'] as List? ?? const []))
        result as Map<String, dynamic>,
    ]..sort((a, b) => (a['posicion'] as int).compareTo(b['posicion'] as int));
    return [for (final result in results) result['foto_id'] as String];
  }

  /// Reads a message. A photo that cannot be found is kept, without a link,
  /// so the answer shows «Foto no disponible» instead of failing (HU-25,
  /// CA5).
  static ChatMessage messageFrom(
    Map<String, dynamic> row,
    Map<String, MemoryPhoto> photos,
  ) {
    return ChatMessage(
      id: row['id'] as String,
      role: row['rol'] == ChatRole.user.name
          ? ChatRole.user
          : ChatRole.assistant,
      text: row['texto'] as String,
      createdAt:
          DateTime.tryParse(row['creado_en'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      photos: [
        for (final id in photoIdsFrom(row)) photos[id] ?? MemoryPhoto(id: id),
      ],
    );
  }
}
