import 'package:flutter/material.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';
import 'package:memorylens/theme/app_theme.dart';

/// The side panel «Búsquedas» with the conversations of the person, the
/// latest activity first (HU-24, CA1, CA2). It closes with the «x» or by
/// tapping outside (CA4).
class ConversationsDrawer extends StatelessWidget {
  static const closeKey = Key('conversations-close');
  static const newKey = Key('conversations-new');

  final List<Conversation> conversations;

  /// The conversation that is open, which is marked.
  final String openId;

  /// False while an answer is on its way or a message waits to be saved:
  /// changing conversation then would leave it behind.
  final bool canSwitch;

  /// Why the list could not be refreshed, if it could not.
  final String? error;

  final VoidCallback onClose;
  final VoidCallback onNew;
  final ValueChanged<Conversation> onOpen;
  final ValueChanged<Conversation> onDelete;

  const ConversationsDrawer({
    super.key,
    required this.conversations,
    required this.openId,
    required this.canSwitch,
    required this.onClose,
    required this.onNew,
    required this.onOpen,
    required this.onDelete,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        'Búsquedas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: closeKey,
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: newKey,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva búsqueda'),
                  onPressed: canSwitch ? onNew : null,
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ErrorMessage(message: error!),
              ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: conversations.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aún no tienes búsquedas guardadas',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final isOpen = conversation.id == openId;
                        final updatedAt = conversation.updatedAt;
                        return ListTile(
                          selected: isOpen,
                          selectedTileColor: AppColors.secondary,
                          selectedColor: AppColors.secondaryForeground,
                          title: Text(
                            conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: updatedAt == null
                              ? null
                              : Text(MemoryDates.dayLabel(updatedAt, now)),
                          // The open one only closes the panel.
                          onTap: isOpen || canSwitch
                              ? () => onOpen(conversation)
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Eliminar ${conversation.title}',
                            // Deleting the open one while it is busy would
                            // leave a message behind.
                            onPressed: isOpen && !canSwitch
                                ? null
                                : () => onDelete(conversation),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
