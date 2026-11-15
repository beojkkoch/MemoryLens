import 'package:flutter/material.dart';

import 'package:memorylens/features/memories/domain/entities/memory_group.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Square thumbnails, three a row, with a thin gap (HU-12, CA1).
const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  mainAxisSpacing: 2,
  crossAxisSpacing: 2,
);

/// The timeline of Recuerdos: a title per day and its photos below (HU-12).
///
/// The tiles are built only as they get close to the screen, so the
/// thumbnails off screen are not downloaded yet (HU-15, CA4).
class MemoriesGrid extends StatelessWidget {
  /// How close to the end, in pixels, the next page is asked for. About
  /// five rows, so it usually arrives before the person gets there (CA2).
  static const loadMoreDistance = 800.0;

  final List<MemoryGroup> groups;
  final ValueChanged<MemoryPhoto> onOpen;

  /// Shows the indicator at the end (HU-15, CA3).
  final bool loadingMore;

  /// Called, maybe many times, while the person is close to the end.
  final VoidCallback? onNearEnd;

  const MemoriesGrid({
    super.key,
    required this.groups,
    required this.onOpen,
    this.loadingMore = false,
    this.onNearEnd,
  });

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < loadMoreDistance) {
      onNearEnd?.call();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        // Keeps the scroll position when the person comes back from a photo
        // (CA7), even if the grid is built again.
        key: const PageStorageKey('memories-grid'),
        slivers: [
          for (final group in groups) ...[
            SliverToBoxAdapter(
              child: _DayTitle(MemoryDates.dayLabel(group.day, now)),
            ),
            SliverGrid.builder(
              gridDelegate: _gridDelegate,
              itemCount: group.photos.length,
              itemBuilder: (context, index) {
                final photo = group.photos[index];
                return MemoryTile(photo: photo, onTap: () => onOpen(photo));
              },
            ),
          ],
          if (loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Cargando más fotos',
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

/// Gray squares in place of the photos while they load (CA9).
class MemoriesGridPlaceholder extends StatelessWidget {
  const MemoriesGridPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando tus recuerdos',
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 44),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate,
        itemCount: 18,
        itemBuilder: (_, _) => const _ThumbnailBox(),
      ),
    );
  }
}

class _DayTitle extends StatelessWidget {
  final String label;

  const _DayTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// One thumbnail, cropped to the center. One that does not load is a gray box
/// with an image icon, and the rest of the grid goes on (CA11).
class MemoryTile extends StatelessWidget {
  final MemoryPhoto photo;
  final VoidCallback onTap;

  const MemoryTile({super.key, required this.photo, required this.onTap});

  String get _title {
    final title = photo.title?.trim();
    return title == null || title.isEmpty ? 'foto' : title;
  }

  @override
  Widget build(BuildContext context) {
    final url = photo.thumbnailUrl;
    return Semantics(
      button: true,
      label: 'Abrir $_title',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: url == null
            ? const _ThumbnailBox(broken: true)
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const _ThumbnailBox(),
                errorBuilder: (_, _, _) => const _ThumbnailBox(broken: true),
              ),
      ),
    );
  }
}

class _ThumbnailBox extends StatelessWidget {
  /// Shows the image icon of a thumbnail that could not load.
  final bool broken;

  const _ThumbnailBox({this.broken = false});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.border,
      child: broken
          ? const Center(
              child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
            )
          : const SizedBox.expand(),
    );
  }
}
