/// 4-pt spacing scale and corner-radius tokens.
///
/// Consistent rhythm across the whole app — never hard-code magic numbers.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner-radius tokens.
abstract final class AppRadius {
  const AppRadius._();

  static const double chip = 12;
  static const double button = 16;
  static const double card = 24;
  static const double sheet = 28;
  static const double pill = 999;
}

/// Motion tokens — one place to tune the whole app's feel.
abstract final class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
