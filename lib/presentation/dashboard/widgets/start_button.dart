import 'package:flutter/material.dart';

import '../../../app/localization/l10n_extension.dart';

/// Button used to start the first automation pipeline.
class StartButton extends StatelessWidget {
  /// Creates a dashboard start button.
  const StartButton({
    required this.onPressed,
    super.key,
  });

  /// Called when the user requests automation start.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(context.l10n.startAutomation),
    );
  }
}
