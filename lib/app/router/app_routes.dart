/// Type-safe route locations for the whole app.
///
/// Centralised here so features never hard-code path strings.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String home = '/home';
  static const String exercises = '/exercises';
  static const String progress = '/progress';
  static const String profile = '/profile';

  // Full-screen (outside the bottom-nav shell) — wired in later modules.
  static const String activeWorkout = '/workout/active';
  static const String programs = '/programs';
  static const String onboarding = '/onboarding';

  static String exerciseDetail(String id) => '/exercises/$id';
}
