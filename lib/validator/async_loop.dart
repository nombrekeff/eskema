/// Helper for async loops
library validator.async_loop;

import 'dart:async';

/// A function that reduces a sequence of [items] into a result [initialState],
/// handling both synchronous and asynchronous [reducer]s.
///
/// If [reducer] returns a [Future], the rest of the iteration will be chained asynchronously.
/// If [reducer] returns a value synchronously, iteration continues synchronously.
///
/// [shouldStop] is an optional check run after each reduction to determine if
/// iteration should terminate early.
FutureOr<S> asyncFold<T, S>(
  Iterable<T> items,
  S initialState,
  FutureOr<S> Function(S state, T item) reducer, {
  bool Function(S state)? shouldStop,
}) {
  final iterator = items.iterator;
  if (!iterator.moveNext()) {
    return initialState;
  }

  // Helper for the recursive loop
  FutureOr<S> loop(S currentState) {
    if (shouldStop != null && shouldStop(currentState)) {
      return currentState;
    }

    final item = iterator.current;
    final result = reducer(currentState, item);

    if (result is Future<S>) {
      return result.then((nextState) {
        if (!iterator.moveNext()) {
          return nextState;
        }
        return loop(nextState);
      });
    }

    if (!iterator.moveNext()) {
      return result;
    }
    
    return loop(result);
  }

  // Initial call
  return loop(initialState);
}
