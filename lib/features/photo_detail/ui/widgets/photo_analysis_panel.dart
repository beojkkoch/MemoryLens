import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/components/primary_button.dart';
import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/save_photo_edit_usecase.dart';
import 'package:memorylens/theme/app_theme.dart';

/// What the AI wrote about the photo and the data it found (HU-28, CA2, CA6),
/// with the category and the purchase data ready to correct and «Hecho» to
/// save them (HU-30).
///
/// The fields live in this State, so a failed save keeps what the person
/// typed (CA8).
class PhotoAnalysisPanel extends StatefulWidget {
  /// Shown for a field with no value (HU-28, CA8).
  static const missing = '—';

  /// Digits, and up to 2 decimals after a dot or a comma. No minus sign, so
  /// a negative amount cannot even be typed (HU-30, CA2, CA3). Ten digits
  /// before the decimals fit in the monto column.
  static final amountPattern = RegExp(r'^\d{0,10}([.,]\d{0,2})?$');

  static const categoryKey = Key('photo-category');
  static const purchaseTypeKey = Key('photo-purchase-type');
  static const amountKey = Key('photo-amount');

  final PhotoDetail detail;
  final List<String> categories;
  final bool saving;
  final String? saveError;
  final ValueChanged<PhotoEdit> onDone;

  const PhotoAnalysisPanel({
    super.key,
    required this.detail,
    required this.categories,
    required this.onDone,
    this.saving = false,
    this.saveError,
  });

  /// The amount typed, or null when the field is empty or not a number.
  static double? parseAmount(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  @override
  State<PhotoAnalysisPanel> createState() => _PhotoAnalysisPanelState();
}

class _PhotoAnalysisPanelState extends State<PhotoAnalysisPanel> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _purchaseType;
  late final TextEditingController _amount;
  String? _category;

  /// The currency of the amount: the photo's own, or the default one for an
  /// invoice that had none.
  late final String _currency;

  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    _category = detail.category;
    _purchaseType = TextEditingController(text: detail.purchaseType ?? '');
    _amount = TextEditingController(text: _amountText(detail.total));
    _currency = detail.total?.currency ?? PhotoEdit.defaultCurrency;
  }

  @override
  void dispose() {
    _purchaseType.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// 23100 for COP, 23.10 for USD: no thousands, so it reads back as typed.
  static String _amountText(Money? total) {
    if (total == null) return '';
    final amount = total.amount;
    return amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }

  /// Hiding the purchase fields keeps their text: it is dropped only when
  /// saving, and only outside «Factura» (HU-29, CA3).
  PhotoEdit get _edit {
    final amount = PhotoAnalysisPanel.parseAmount(_amount.text);
    final type = _purchaseType.text.trim();
    return PhotoEdit(
      category: _category,
      purchaseType: type.isEmpty ? null : type,
      total: amount == null ? null : Money(amount: amount, currency: _currency),
    );
  }

  void _done() {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    widget.onDone(_edit);
  }

  String? _validateAmount(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final amount = PhotoAnalysisPanel.parseAmount(text);
    if (amount == null || amount <= 0) {
      return SavePhotoEditUseCase.invalidAmountMessage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final takenAt = detail.takenAt;
    return Form(
      key: _form,
      child: Padding(
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
                // Never editable (HU-28, CA7).
                child: _Value(
                  takenAt == null ? null : MemoryDates.dateTimeLabel(takenAt),
                ),
              ),
              second: _Field(
                label: 'Categoría',
                child: _CategoryField(
                  value: _category,
                  categories: widget.categories,
                  onChanged: (value) => setState(() => _category = value),
                ),
              ),
            ),
            // No purchase data on a landscape (HU-29, CA1).
            if (PhotoDetail.hasPurchaseFields(_category)) ...[
              const SizedBox(height: 16),
              _FieldRow(
                first: _Field(
                  label: 'Tipo de compra',
                  child: TextFormField(
                    key: PhotoAnalysisPanel.purchaseTypeKey,
                    controller: _purchaseType,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(),
                  ),
                ),
                second: _Field(
                  label: 'Monto total',
                  child: TextFormField(
                    key: PhotoAnalysisPanel.amountKey,
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (old, value) =>
                            PhotoAnalysisPanel.amountPattern.hasMatch(
                              value.text,
                            )
                            ? value
                            : old,
                      ),
                    ],
                    validator: _validateAmount,
                    decoration: _inputDecoration().copyWith(
                      // The symbol of the currency, always visible (CA2).
                      prefixText: '${Money.symbolFor(_currency)} ',
                    ),
                  ),
                ),
              ),
            ],
            if (widget.saveError != null) ...[
              const SizedBox(height: 16),
              ErrorMessage(message: widget.saveError!),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Hecho',
              isLoading: widget.saving,
              onPressed: _done,
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  return const InputDecoration(
    hintText: PhotoAnalysisPanel.missing,
    isDense: true,
    counterText: '',
  );
}

/// The categories of the system to choose from; an empty one is not
/// accepted (HU-30, CA5).
class _CategoryField extends StatelessWidget {
  final String? value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryField({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // A category that is no longer in the catalog still shows, so the
    // person sees what the photo has.
    final options = [
      ...categories,
      if (value != null && !categories.contains(value)) value!,
    ];
    return DropdownButtonFormField<String>(
      key: PhotoAnalysisPanel.categoryKey,
      initialValue: value,
      isExpanded: true,
      decoration: _inputDecoration(),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
      validator: (value) => value == null || value.trim().isEmpty
          ? SavePhotoEditUseCase.missingCategoryMessage
          : null,
    );
  }
}

/// Two fields side by side (HU-28, CA6).
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
  final Widget child;

  const _Field({required this.label, required this.child});

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
        child,
      ],
    );
  }
}

/// A value that cannot be edited.
class _Value extends StatelessWidget {
  final String? value;

  const _Value(this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        value ?? PhotoAnalysisPanel.missing,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
