import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/progress_stats.dart';
import '../repositories/progress_repository.dart';

/// Holds the signed-in student's learning progress. Data is loaded from the
/// backend (scoped by Firebase UID) with a local-cache fallback, so each
/// account sees only its own points, streak, history and activity.
///
/// Held as a singleton so the home and profile screens stay in sync; it is
/// [reset] on logout so the next account never inherits stale stats.
class ProgressCubit extends Cubit<ProgressStats> {
  final ProgressRepository _repository;

  ProgressCubit(this._repository) : super(const ProgressStats());

  Future<void> load() async {
    final stats = await _repository.getProgress();
    if (isClosed) return;
    emit(stats);
  }

  /// Clears in-memory progress immediately (used on logout).
  void reset() {
    if (isClosed) return;
    emit(const ProgressStats());
  }
}
