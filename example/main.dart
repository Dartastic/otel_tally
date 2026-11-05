// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_tally/otel_tally.dart';

/// Traces Tally calls with OpenTelemetry.
///
/// `otel_tally` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Tally call in
/// [tracedTally]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'tally-example');

  // Wraps a Tally API call in a CLIENT span.
  final tallyId = await tracedTally<String>(
    operation: 'webhooks.create',
    invoke: () async {
      // Make the Tally call here, then report what it returned.
      const id = 'tally_8f3a2c';
      return const TallyCallResult(
          value: id,
          result: TallyResult(
              workspaceId: 'workspace_8f3a2c',
              formId: 'form_8f3a2c',
              formStatus: 'PUBLISHED',
              questionCount: 3,
              hasPaymentBlock: true,
              hasFileUpload: true,
              partialSubmissionsEnabled: true,
              submissionId: 'submission_8f3a2c',
              completedAtSec: 1,
              respondentEmail: 'ada@example.com',
              responseCountForForm: 3,
              webhookId: 'webhook_8f3a2c',
              webhookEnabled: true,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedTally webhooks.create returned $tallyId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutTallyInstrumentationAsync.
  await runWithoutTallyInstrumentationAsync(
    () => tracedTally<String>(
      operation: 'webhooks.create',
      invoke: () async {
        const id = 'tally_8f3a2c';
        return const TallyCallResult(
            value: id,
            result: TallyResult(
                workspaceId: 'workspace_8f3a2c',
                formId: 'form_8f3a2c',
                formStatus: 'PUBLISHED',
                questionCount: 3,
                hasPaymentBlock: true,
                hasFileUpload: true,
                partialSubmissionsEnabled: true,
                submissionId: 'submission_8f3a2c',
                completedAtSec: 1,
                respondentEmail: 'ada@example.com',
                responseCountForForm: 3,
                webhookId: 'webhook_8f3a2c',
                webhookEnabled: true,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
