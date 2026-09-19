import 'package:flutter_test/flutter_test.dart';
import 'package:hackthon2/features/assistant/models/context_resolution.dart';

void main() {
  test('ready stores selected report candidate', () {
    final candidate = ContextCandidate(
      id: 'report_1',
      type: HealthContextType.report,
      title: 'Blood Test',
      subtitle: '18 Sep 2026',
      data: {
        'title': 'Blood Test',
      },
    );

    final result = ContextResolution.ready(
      type: HealthContextType.report,
      candidate: candidate,
    );

    expect(
      result.status,
      ContextResolutionStatus.ready,
    );

    expect(
      result.selected?.id,
      'report_1',
    );

    expect(
      result.isReady,
      true,
    );
  });
}
