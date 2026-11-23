import 'package:flutter/material.dart';

import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/ui/widgets/memories_grid.dart';
import 'package:memorylens/theme/app_theme.dart';

/// A photo of an answer: the same square thumbnail as Recuerdos. A photo
/// with no link, because its file is gone, says «Foto no disponible» instead
/// of failing (HU-25, CA5).
class ChatPhotoTile extends StatelessWidget {
  final MemoryPhoto photo;
  final VoidCallback onTap;

  const ChatPhotoTile({super.key, required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (photo.thumbnailUrl == null) return const _UnavailablePhoto();
    return MemoryTile(photo: photo, onTap: onTap);
  }
}

class _UnavailablePhoto extends StatelessWidget {
  const _UnavailablePhoto();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Foto no disponible',
      excludeSemantics: true,
      child: const ColoredBox(
        color: AppColors.border,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              'Foto no disponible',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
