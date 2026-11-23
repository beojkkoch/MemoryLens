import 'package:flutter/material.dart';

import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/ui/widgets/chat_photo_tile.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/theme/app_theme.dart';

/// One message of the conversation: the question of the person on the right
/// with the main color (HU-20, CA4), the answer of the assistant on the left
/// with its photos in a grid of three columns.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<MemoryPhoto> onOpenPhoto;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onOpenPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : AppColors.background,
            border: isUser ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? AppColors.primaryForeground
                      : AppColors.textPrimary,
                ),
              ),
              if (message.photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final photo in message.photos)
                        ChatPhotoTile(
                          photo: photo,
                          onTap: () => onOpenPhoto(photo),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
