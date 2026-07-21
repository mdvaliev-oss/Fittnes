import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/exercises/presentation/exercises_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import 'app_routes.dart';
import 'scaffold_with_nav.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// App-wide router. Exposed as a provider so later modules can react to
/// auth / onboarding state via `refreshListenable`.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ScaffoldWithNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) =>
                    _fade(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.exercises,
                pageBuilder: (context, state) =>
                    _fade(state, const ExercisesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                pageBuilder: (context, state) =>
                    _fade(state, const ProgressScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    _fade(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Consistent fade-through transition between tab roots.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
        child: child,
      );
    },
  );
}
