import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/repository/photo_search_repository.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/injection_container.dart';

/// Looks for the photos a question asks for and writes the answer of the
/// assistant (HU-20).
class AnswerQuestionUseCase {
  static const foundText = 'Aquí tienes las coincidencias:';
  static const notFoundText = 'No encontré fotos que coincidan';

  final PhotoSearchRepository _search = sl();

  Future<ChatMessage> call(String question) async {
    final text = question.trim();
    if (text.isEmpty) throw const AppException('Escribe tu pregunta');
    final photos = await _search.search(text);
    // Never random photos when nothing matches.
    return ChatMessage.answer(
      photos.isEmpty ? notFoundText : foundText,
      photos: photos,
    );
  }
}
