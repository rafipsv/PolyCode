import 'dart:async';

/// Token that can be signalled to cancel an ongoing execution.
class CancellationToken {
  CancellationToken();

  bool _isCancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  /// Cancels the associated operation and triggers all registered callbacks.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  /// Registers a callback to be invoked when cancelled.
  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _listeners.add(callback);
    }
  }

  /// Returns a Future that completes when cancelled.
  Future<void> get whenCancelled {
    if (_isCancelled) return Future.value();
    final completer = Completer<void>();
    onCancel(() {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }
}
