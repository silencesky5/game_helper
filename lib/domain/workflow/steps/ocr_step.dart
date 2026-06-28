import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that represents an OCR instruction for a named region.
class OCRStep extends WorkflowStep {
  /// Region identifier to be used by a future OCR executor.
  final String region;

  /// Runtime variable name intended to receive OCR output.
  final String variable;

  /// Creates an immutable OCR workflow step.
  const OCRStep({
    required super.id,
    required this.region,
    required this.variable,
  }) : super(type: 'ocr');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {}
}
