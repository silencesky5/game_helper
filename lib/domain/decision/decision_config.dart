import 'dart:convert';
import 'dart:io';

import 'recovery_policy.dart';

class DecisionConfig {
  const DecisionConfig({required this.retryCount, required this.timeout, required this.decisionInterval, required this.recoveryPolicy});

  final int retryCount;
  final Duration timeout;
  final Duration decisionInterval;
  final RecoveryStrategy recoveryPolicy;

  RecoveryPolicy get policy => RecoveryPolicy(strategy: recoveryPolicy, maxRetries: retryCount, timeout: timeout);

  static const DecisionConfig defaults = DecisionConfig(
    retryCount: 3,
    timeout: Duration(seconds: 30),
    decisionInterval: Duration(seconds: 1),
    recoveryPolicy: RecoveryStrategy.retry,
  );

  static DecisionConfig loadSync({String path = 'config/decision.json'}) {
    final file = File(path);
    if (!file.existsSync()) return defaults;
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return _fromMap(data);
  }

  static Future<DecisionConfig> load({String path = 'config/decision.json'}) async {
    final file = File(path);
    if (!file.existsSync()) return defaults;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return _fromMap(data);
  }

  static DecisionConfig _fromMap(Map<String, dynamic> data) {
    return DecisionConfig(
      retryCount: data['retryCount'] as int? ?? defaults.retryCount,
      timeout: Duration(milliseconds: data['timeoutMs'] as int? ?? defaults.timeout.inMilliseconds),
      decisionInterval: Duration(milliseconds: data['decisionIntervalMs'] as int? ?? defaults.decisionInterval.inMilliseconds),
      recoveryPolicy: RecoveryStrategy.values.firstWhere(
        (strategy) => strategy.name == (data['recoveryPolicy'] as String? ?? 'retry'),
        orElse: () => defaults.recoveryPolicy,
      ),
    );
  }
}
