import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Top bar with the back arrow, the "MEMORY LENS" label and the screen title.
/// [onBack] replaces the default pop, e.g. to go back one step of a form.
class MemoryLensAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onBack;

  const MemoryLensAppBar({super.key, required this.title, this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      centerTitle: false,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const BackButtonIcon(),
              tooltip: 'Volver',
              onPressed: () => onBack!(),
            ),
      titleSpacing: 0,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEMORY LENS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
