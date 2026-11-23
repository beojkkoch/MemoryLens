/// Something the chat asks the ChatBloc to do.
abstract class ChatEvent {}

/// The chat opened, or the person pressed «Reintentar» after a failed load.
/// With an id it opens that conversation (an id that is not saved yet is an
/// empty one); with none, the latest one, or an empty one if there are none
/// (HU-13, CA4).
class ChatStarted extends ChatEvent {
  final String? conversationId;

  ChatStarted([this.conversationId]);

  @override
  String toString() {
    return 'ChatStarted($conversationId)';
  }
}

/// The person sent a question, with the button or with Enter (HU-20, CA2).
class ChatQuestionSent extends ChatEvent {
  final String text;

  ChatQuestionSent(this.text);

  @override
  String toString() {
    return 'ChatQuestionSent($text)';
  }
}

/// The person pressed «Reintentar» after a message could not be saved
/// (HU-25, CA4).
class ChatSaveRetried extends ChatEvent {
  @override
  String toString() {
    return 'ChatSaveRetried()';
  }
}
