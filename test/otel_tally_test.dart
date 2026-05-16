// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_tally/otel_tally.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_tally-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('forms.get records status + payment + uploads', () async {
    await tracedTally<String>(
      operation: 'forms.get',
      invoke: () async => const TallyCallResult(
        value: 'ok',
        result: TallyResult(
          workspaceId: 'ws_1',
          formId: 'frm_1',
          formStatus: 'PUBLISHED',
          questionCount: 12,
          hasPaymentBlock: true,
          hasFileUpload: true,
          partialSubmissionsEnabled: true,
          responseCountForForm: 480,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('tally forms.get')!);
    expect(a['tally.form.status'], 'PUBLISHED');
    expect(a['tally.form.question_count'], 12);
    expect(a['tally.form.has_payment'], true);
    expect(a['tally.form.has_file_upload'], true);
    expect(a['tally.form.response_count'], 480);
  });

  test('submissions.get records submission + email', () async {
    await tracedTally<String>(
      operation: 'submissions.get',
      invoke: () async => const TallyCallResult(
        value: 'ok',
        result: TallyResult(
          submissionId: 'sub_1',
          completedAtSec: 1731600000,
          respondentEmail: 'user@example.com',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('tally submissions.get')!);
    expect(a['tally.submission.id'], 'sub_1');
    expect(a['tally.submission.completed_at_sec'], 1731600000);
    expect(a['tally.respondent.email'], 'user@example.com');
  });

  test('HTTP 404 sets span error', () async {
    await tracedTally<String>(
      operation: 'forms.get',
      invoke: () async => const TallyCallResult(
        value: 'ok',
        result: TallyResult(statusCode: 404),
      ),
    );
    expect(
      spans.findSpanByName('tally forms.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutTallyInstrumentationAsync(() async {
      await tracedTally<String>(
        operation: 'forms.list',
        invoke: () async => const TallyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('tally '), isEmpty);
  });
}
