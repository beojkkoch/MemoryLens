/// How the dates of the timeline read in Spanish (HU-12). Written by hand so
/// the app does not need a localization package for a few month names.
class MemoryDates {
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _shortMonths = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// Title of a group: «Hoy», «Ayer» or «15 jun 2024» (CA2). [day] is null
  /// for the photos with no capture date.
  static String dayLabel(DateTime? day, DateTime now) {
    if (day == null) return 'Sin fecha';
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(day.year, day.month, day.day);
    if (date == today) return 'Hoy';
    if (date == DateTime(today.year, today.month, today.day - 1)) {
      return 'Ayer';
    }
    return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
  }

  /// «Junio 2024» (CA5).
  static String monthLabel(DateTime date) {
    return '${_months[date.month - 1]} ${date.year}';
  }
}
