import '../perception/perception_types.dart';
import 'action_plan.dart';

/// Goal interface implemented by game plugins.
abstract class Goal {
  const Goal();
  String get id;
  String get name;
  ActionPlan nextAction(PerceptionResult? perception);
}
