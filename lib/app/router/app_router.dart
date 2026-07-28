import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/exercises/presentation/exercise_detail_screen.dart';
import '../../features/exercises/presentation/exercises_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/nutrition/presentation/nutrition_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/programs/presentation/program_builder_screen.dart';
import '../../features/programs/presentation/program_detail_screen.dart';
import '../../features/programs/presentation/programs_screen.dart';
import '../../features/recovery/presentation/recovery_screen.dart';
import '../../features/workout/presentation/active_workout_screen.dart';
import '../../features/workout/presentation/workout_history_screen.dart';
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
      // Full-screen exercise detail (over the bottom-nav shell).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/exercises/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: ExerciseDetailScreen(exerciseId: id),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondary, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          );
        },
      ),
      // Full-screen active workout (slides up over everything).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.activeWorkout,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const ActiveWorkoutScreen(),
          transitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondary, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.programs,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ProgramsScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.programBuilder,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const ProgramBuilderScreen(),
          transitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/programs/:id',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: ProgramDetailScreen(programId: state.pathParameters['id']!),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.recovery,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const RecoveryScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.history,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const WorkoutHistoryScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNav(navigationShell: shell),
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
                path: AppRoutes.nutrition,
                pageBuilder: (context, state) =>
                    _fade(state, const NutritionScreen()),
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
