import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// Rounded pill that the user taps to pick or drop an interest.
class InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function() onTap;

  const InterestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => onTap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.primaryForeground
                  : AppColors.secondaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}
