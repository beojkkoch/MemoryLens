import 'package:flutter/material.dart';

import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/theme/app_theme.dart';

/// What the AI wrote about the photo and the data it found (HU-28, CA2, CA6).
/// Nothing here can be edited.
class PhotoAnalysisPanel extends StatelessWidget {
  /// Shown for a field with no value (CA8).
  static const missing = '—';

  final PhotoDetail detail;

  const PhotoAnalysisPanel({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final takenAt = detail.takenAt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANÁLISIS DE IA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.sell_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    detail.title ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (detail.description != null) ...[
            const SizedBox(height: 8),
            Text(
              detail.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _FieldRow(
            first: _Field(
              label: 'Fecha',
              value: takenAt == null
                  ? null
                  : MemoryDates.dateTimeLabel(takenAt),
            ),
            second: _Field(label: 'Categoría', value: detail.category),
          ),
          const SizedBox(height: 16),
          _FieldRow(
            first: _Field(label: 'Tipo de compra', value: detail.purchaseType),
            second: _Field(label: 'Monto total', value: detail.total?.format()),
          ),
        ],
      ),
    );
  }
}

/// Two fields side by side (CA6).
class _FieldRow extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _FieldRow({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? PhotoAnalysisPanel.missing,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
