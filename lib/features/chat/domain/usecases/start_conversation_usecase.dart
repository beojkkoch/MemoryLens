import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:uuid/uuid.dart';

/// Opens an empty conversation with an address of its own (HU-23, CA2). It
/// is not saved until the first message, so leaving it empty leaves no trace
/// in the history (CA4), and the previous conversation stays as it was (CA3).
class StartConversationUseCase {
  Conversation call() => Conversation.draft(const Uuid().v4());
}
