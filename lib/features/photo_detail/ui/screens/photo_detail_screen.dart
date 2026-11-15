import 'package:flutter/material.dart';

import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';
import 'package:memorylens/theme/app_theme.dart';

/// The photo opened from Recuerdos (HU-12, CA7). For now it shows the image,
/// its title and its date; the rest of the detail comes with HU-28.
class PhotoDetailScreen extends StatelessWidget {
  final MemoryPhoto photo;

  const PhotoDetailScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final title = photo.title?.trim();
    final url = photo.imageUrl;
    return Scaffold(
      appBar: MemoryLensAppBar(
        title: title == null || title.isEmpty ? 'Foto' : title,
        subtitle: MemoryDates.dayLabel(photo.takenAt, DateTime.now()),
        onBack: () => Navigator.pop(context),
      ),
      body: ColoredBox(
        color: AppColors.canvas,
        child: Center(
          child: url == null
              ? const _ImageMissing()
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  semanticLabel: title,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const CircularProgressIndicator(),
                  errorBuilder: (_, _, _) => const _ImageMissing(),
                ),
        ),
      ),
    );
  }
}

class _ImageMissing extends StatelessWidget {
  const _ImageMissing();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image_outlined, size: 48, color: AppColors.textSecondary),
        SizedBox(height: 8),
        Text(
          'No pudimos cargar esta foto',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
