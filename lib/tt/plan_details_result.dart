class PlanDetailsResult {
  final String name;
  final String description;
  final String? masterPlanId;
  final List<String> guidelineIds;
  final List<String> diagnosisIds;
  final String? linkedVitalsId;

  PlanDetailsResult({
    required this.name,
    this.description = '',
    this.masterPlanId,
    this.guidelineIds = const [],
    this.diagnosisIds = const [],
    this.linkedVitalsId,
  });
}