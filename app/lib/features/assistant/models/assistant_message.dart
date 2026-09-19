class AssistantMessage {
  final String role;
  final String text;
  final DateTime createdAt;
  final List<String> contextLabels;
  final Map<String, dynamic>? doctorRecommendation;

  AssistantMessage({
    required this.role,
    required this.text,
    required this.createdAt,
    this.contextLabels = const [],
    this.doctorRecommendation,
  });
}