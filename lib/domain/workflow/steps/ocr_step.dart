import '../../perception/perception_types.dart';
import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Legacy text-reading workflow step that consumes PerceptionResult OCR text.
///
/// Workflows must not call OCR directly; this step only reads semantic data that
/// has already been produced by the platform PerceptionService.
class OCRStep extends WorkflowStep {
  /// Optional semantic region identifier for workflow authors.
  final String region;

  /// Runtime variable name that receives OCR text from the latest perception result.
  final String variable;

  /// Creates an immutable OCR workflow step.
  const OCRStep({
    required super.id,
    required this.region,
    required this.variable,
  }) : super(type: 'ocr');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {
    final Object? semantic = runtime.getVariable('perceptionResult');
    if (semantic is PerceptionResult) {
      runtime.setVariable(variable, semantic.ocr.preview);
    }
  }
}
