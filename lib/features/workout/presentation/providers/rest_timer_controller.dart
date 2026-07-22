import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable snapshot of the rest countdown.
class RestTimerState {
  const RestTimerState({
    this.total = 0,
    this.remaining = 0,
    this.running = false,
  });

  final int total;
  final int remaining;
  final bool running;

  bool get isActive => running || remaining > 0;
  double get progress => total == 0 ? 0 : remaining / total;

  RestTimerState copyWith({int? total, int? remaining, bool? running}) {
    return RestTimerState(
      total: total ?? this.total,
      remaining: remaining ?? this.remaining,
      running: running ?? this.running,
    );
  }
}

/// Drives the automatic rest countdown after a set is completed.
class RestTimerController extends Notifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() {
    ref.onDispose(_cancel);
    return const RestTimerState();
  }

  void start(int seconds) {
    _cancel();
    state = RestTimerState(total: seconds, remaining: seconds, running: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void addSeconds(int delta) {
    if (!state.isActive) return;
    final remaining = (state.remaining + delta).clamp(0, 60 * 60);
    final total = remaining > state.total ? remaining : state.total;
    state = state.copyWith(
      remaining: remaining,
      total: total,
      running: remaining > 0,
    );
    if (remaining == 0) _cancel();
  }

  void skip() {
    _cancel();
    state = const RestTimerState();
  }

  void _tick() {
    final remaining = state.remaining - 1;
    if (remaining <= 0) {
      _cancel();
      state = state.copyWith(remaining: 0, running: false);
    } else {
      state = state.copyWith(remaining: remaining);
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

final restTimerProvider = NotifierProvider<RestTimerController, RestTimerState>(
  RestTimerController.new,
);
