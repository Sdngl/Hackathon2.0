enum HealthContextType {
  report,
  medicine,
  meal,
}

enum ContextResolutionStatus {
  general,
  ready,
  needsSelection,
  missing,
}

class ContextCandidate {
  final String id;
  final HealthContextType type;
  final String title;
  final String subtitle;
  final Map<String, dynamic> data;

  const ContextCandidate({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.data,
  });
}

class ContextResolution {
  final ContextResolutionStatus status;

  final HealthContextType? contextType;

  final ContextCandidate? selected;

  final List<ContextCandidate> candidates;

  final String? message;

  const ContextResolution._({
    required this.status,
    this.contextType,
    this.selected,
    this.candidates = const [],
    this.message,
  });

  factory ContextResolution.general() {
    return const ContextResolution._(
      status: ContextResolutionStatus.general,
    );
  }

  factory ContextResolution.ready({
    required HealthContextType type,
    required ContextCandidate candidate,
  }) {
    return ContextResolution._(
      status: ContextResolutionStatus.ready,
      contextType: type,
      selected: candidate,
      candidates: [candidate],
    );
  }

  factory ContextResolution.needsSelection({
    required HealthContextType type,
    required List<ContextCandidate> candidates,
  }) {
    return ContextResolution._(
      status: ContextResolutionStatus.needsSelection,
      contextType: type,
      candidates: candidates,
    );
  }

  factory ContextResolution.missing({
    required HealthContextType type,
    required String message,
  }) {
    return ContextResolution._(
      status: ContextResolutionStatus.missing,
      contextType: type,
      message: message,
    );
  }

  bool get isGeneral {
    return status == ContextResolutionStatus.general;
  }

  bool get isReady {
    return status == ContextResolutionStatus.ready;
  }

  bool get needsSelection {
    return status == ContextResolutionStatus.needsSelection;
  }

  bool get isMissing {
    return status == ContextResolutionStatus.missing;
  }
}