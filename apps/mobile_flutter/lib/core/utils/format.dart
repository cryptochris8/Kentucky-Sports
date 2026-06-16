import 'package:intl/intl.dart';

/// Formatting helpers for dates, countdowns, and stat values.
abstract final class Fmt {
  static final DateFormat _dayMonth = DateFormat('EEE, MMM d');
  static final DateFormat _dayMonthYear = DateFormat('MMM d, yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _shortDay = DateFormat('MMM d');
  static final DateFormat _weekday = DateFormat('EEEE');

  /// "Sat, Sep 5" style.
  static String dayMonth(DateTime? d) =>
      d == null ? 'TBD' : _dayMonth.format(d.toLocal());

  /// Full weekday name, e.g. "Saturday".
  static String weekday(DateTime? d) =>
      d == null ? 'soon' : _weekday.format(d.toLocal());

  /// "Sep 5, 2026" style.
  static String dayMonthYear(DateTime? d) =>
      d == null ? 'TBD' : _dayMonthYear.format(d.toLocal());

  /// "7:00 PM" style.
  static String time(DateTime? d) =>
      d == null ? '' : _time.format(d.toLocal());

  /// "Sep 5" style.
  static String shortDay(DateTime? d) =>
      d == null ? 'TBD' : _shortDay.format(d.toLocal());

  /// "Sat, Sep 5 · 7:00 PM" combined.
  static String gameDateTime(DateTime? d) {
    if (d == null) return 'Date TBD';
    return '${dayMonth(d)} · ${time(d)}';
  }

  /// A human countdown like "12d 4h", "4h 12m", or "Starting soon".
  static String countdown(DateTime? target, {DateTime? from}) {
    if (target == null) return '—';
    final DateTime now = from ?? DateTime.now();
    final Duration diff = target.difference(now);
    if (diff.isNegative) return 'In progress';
    final int days = diff.inDays;
    final int hours = diff.inHours % 24;
    final int minutes = diff.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 1) return '${minutes}m';
    return 'Starting soon';
  }

  /// Structured countdown parts for a segmented display.
  static ({int days, int hours, int minutes, bool live}) countdownParts(
    DateTime? target, {
    DateTime? from,
  }) {
    if (target == null) {
      return (days: 0, hours: 0, minutes: 0, live: false);
    }
    final DateTime now = from ?? DateTime.now();
    final Duration diff = target.difference(now);
    if (diff.isNegative) {
      return (days: 0, hours: 0, minutes: 0, live: true);
    }
    return (
      days: diff.inDays,
      hours: diff.inHours % 24,
      minutes: diff.inMinutes % 60,
      live: false,
    );
  }

  /// "closes in 2h" style copy for predictions.
  static String closesIn(DateTime? closesAt, {DateTime? from}) {
    if (closesAt == null) return 'Open';
    final DateTime now = from ?? DateTime.now();
    if (closesAt.isBefore(now)) return 'Closed';
    return 'Closes in ${countdown(closesAt, from: now)}';
  }

  /// Title-cases a sport key, e.g. `mens_basketball` -> "Men's Basketball".
  static String sportLabel(String sport) {
    switch (sport) {
      case 'football':
        return 'Football';
      case 'mens_basketball':
        return "Men's Basketball";
      case 'womens_basketball':
        return "Women's Basketball";
      case 'baseball':
        return 'Baseball';
      case 'volleyball':
        return 'Volleyball';
      case 'high_school':
        return 'High School';
      default:
        return sport
            .split('_')
            .map((String w) =>
                w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

  /// Compact integer, e.g. 5400 -> "5,400".
  static String number(int n) => NumberFormat.decimalPattern().format(n);

  /// Percent from a 0..1 ratio, e.g. 0.552 -> "55%".
  static String percent(double ratio, {int decimals = 0}) =>
      '${(ratio * 100).toStringAsFixed(decimals)}%';
}
