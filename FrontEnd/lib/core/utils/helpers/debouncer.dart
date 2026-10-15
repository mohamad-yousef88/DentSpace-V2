import 'dart:async';

import 'package:flutter/foundation.dart';

/// Delays execution until the caller stops invoking it for `delay`.
/// Useful for search-as-you-type, resize handlers, etc.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});
  final Duration delay;
  Timer? _timer;

  VoidCallback? _pendingAction;

  void run(VoidCallback action) {
    _timer?.cancel();
    _pendingAction = action;
    _timer = Timer(delay, () {
      _pendingAction?.call();
      _pendingAction = null;
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pendingAction = null;
  }

  bool get isActive => _timer?.isActive ?? false;

  void dispose() => cancel();
}
