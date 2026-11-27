import 'package:intl/intl.dart';

/// All money in SquirrelStash is stored as integer cents to avoid floating
/// point drift. These helpers format and parse user-facing amounts.
abstract final class Money {
  static final NumberFormat _whole =
      NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0);
  static final NumberFormat _cents =
      NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);

  /// `$6,050` — rounded to the nearest dollar.
  static String whole(int cents) => _whole.format((cents / 100).round());

  /// `$12` for whole-dollar values, `$2.50` otherwise.
  static String smart(int cents) =>
      cents % 100 == 0 ? whole(cents) : _cents.format(cents / 100);

  /// Always two decimals: `$3.09`.
  static String exact(int cents) => _cents.format(cents / 100);

  /// Plain number for text fields: `12` or `2.5`.
  static String plain(int cents) {
    if (cents % 100 == 0) return '${cents ~/ 100}';
    final s = (cents / 100).toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

  static int fromDollars(num dollars) => (dollars * 100).round();

  /// Parses `12`, `$1,250.50`, ` 7.5 ` into cents. Returns null when the
  /// input is empty, malformed or negative.
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s$,]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return null;
    }
    return fromDollars(value);
  }
}
