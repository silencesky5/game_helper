import 'dart:collection';

import '../action/device_action.dart';
import '../core/result.dart';

/// Per-session FIFO command queue. Retry and cancel hooks are reserved.
class CommandQueue {
  final Queue<DeviceAction> _queue = Queue<DeviceAction>();
  bool _cancelRequested = false;

  void enqueue(DeviceAction action) => _queue.addLast(action);

  Future<Result<void>> execute(ActionContext context) async {
    _cancelRequested = false;
    while (_queue.isNotEmpty && !_cancelRequested) {
      final Result<void> result = await _queue.removeFirst().execute(context);
      if (result.isFailure) return result;
    }
    return const Success<void>(null);
  }

  Future<Result<void>> retry(ActionContext context) => execute(context);

  void cancel() {
    _cancelRequested = true;
    _queue.clear();
  }
}
