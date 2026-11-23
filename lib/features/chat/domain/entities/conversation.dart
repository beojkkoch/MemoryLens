/// One search chat of the person, as the list of conversations shows it
/// (HU-24).
class Conversation {
  /// Title of a conversation that has no question yet (HU-23, CA2).
  static const defaultTitle = 'Nueva búsqueda';

  /// A longer first question is cut here, so the title fits the app bar and
  /// the panel.
  static const maxTitleLength = 40;

  final String id;
  final String title;

  /// Last activity, which orders the list (HU-24, CA2). Null for a
  /// conversation that is not saved yet.
  final DateTime? updatedAt;

  const Conversation({required this.id, required this.title, this.updatedAt});

  /// The id comes from the app and the conversation reaches the account with
  /// its first message, so an empty one never shows in the history (HU-23,
  /// CA4).
  const Conversation.draft(String id) : this(id: id, title: defaultTitle);

  /// The title a conversation gets from its first question: the spaces
  /// collapsed and a long text cut with «…».
  static String titleFor(String question) {
    final text = question.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return defaultTitle;
    if (text.length <= maxTitleLength) return text;
    return '${text.substring(0, maxTitleLength).trimRight()}…';
  }

  @override
  String toString() => 'Conversation($id, $title)';
}
