// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_tally_suppression.dart';

const _tracerName = 'dartastic_otel_libs_tally';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class TallyResult {
  const TallyResult({
    this.workspaceId,
    this.formId,
    this.formStatus,
    this.questionCount,
    this.hasPaymentBlock,
    this.hasFileUpload,
    this.partialSubmissionsEnabled,
    this.submissionId,
    this.completedAtSec,
    this.respondentEmail,
    this.responseCountForForm,
    this.webhookId,
    this.webhookEnabled,
    this.statusCode,
  });

  /// Tally workspace.
  final String? workspaceId;

  final String? formId;

  /// `PUBLISHED` / `DRAFT` / `BLANK`.
  final String? formStatus;

  /// Total number of question blocks in the form.
  final int? questionCount;

  /// `true` when the form has a Tally Pay payment block (Stripe-backed).
  final bool? hasPaymentBlock;

  /// `true` when the form accepts file uploads.
  final bool? hasFileUpload;

  /// `true` if the form is configured to capture partial submissions.
  final bool? partialSubmissionsEnabled;

  final String? submissionId;

  /// Unix sec the submission was completed.
  final int? completedAtSec;

  /// Captured if the form has an email field (id only — Tally returns
  /// the value).
  final String? respondentEmail;

  /// Total submissions Tally has for this form.
  final int? responseCountForForm;

  final String? webhookId;
  final bool? webhookEnabled;

  final int? statusCode;
}

class TallyCallResult<T> {
  const TallyCallResult({required this.value, this.result});
  final T value;
  final TallyResult? result;
}

/// Wraps a Tally API call in a CLIENT span. [operation] is one of
/// `forms.list`, `forms.get`, `submissions.list`,
/// `submissions.get`, `webhooks.list`, `webhooks.create`,
/// `webhooks.delete`, `workspaces.list`.
Future<T> tracedTally<T>({
  required String operation,
  required Future<TallyCallResult<T>> Function() invoke,
}) async {
  if (tallyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'tally',
    'rpc.method': operation,
    'tally.operation': operation,
  };

  final span = _tracer().startSpan(
    'tally $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.workspaceId != null) {
        extras.add(OTel.attributeString(
          'tally.workspace.id',
          r.result!.workspaceId!,
        ));
      }
      if (r.result!.formId != null) {
        extras.add(OTel.attributeString(
          'tally.form.id',
          r.result!.formId!,
        ));
      }
      if (r.result!.formStatus != null) {
        extras.add(OTel.attributeString(
          'tally.form.status',
          r.result!.formStatus!,
        ));
      }
      if (r.result!.questionCount != null) {
        extras.add(OTel.attributeInt(
          'tally.form.question_count',
          r.result!.questionCount!,
        ));
      }
      if (r.result!.hasPaymentBlock != null) {
        extras.add(OTel.attributeBool(
          'tally.form.has_payment',
          r.result!.hasPaymentBlock!,
        ));
      }
      if (r.result!.hasFileUpload != null) {
        extras.add(OTel.attributeBool(
          'tally.form.has_file_upload',
          r.result!.hasFileUpload!,
        ));
      }
      if (r.result!.partialSubmissionsEnabled != null) {
        extras.add(OTel.attributeBool(
          'tally.form.partial_submissions_enabled',
          r.result!.partialSubmissionsEnabled!,
        ));
      }
      if (r.result!.submissionId != null) {
        extras.add(OTel.attributeString(
          'tally.submission.id',
          r.result!.submissionId!,
        ));
      }
      if (r.result!.completedAtSec != null) {
        extras.add(OTel.attributeInt(
          'tally.submission.completed_at_sec',
          r.result!.completedAtSec!,
        ));
      }
      if (r.result!.respondentEmail != null) {
        extras.add(OTel.attributeString(
          'tally.respondent.email',
          r.result!.respondentEmail!,
        ));
      }
      if (r.result!.responseCountForForm != null) {
        extras.add(OTel.attributeInt(
          'tally.form.response_count',
          r.result!.responseCountForForm!,
        ));
      }
      if (r.result!.webhookId != null) {
        extras.add(OTel.attributeString(
          'tally.webhook.id',
          r.result!.webhookId!,
        ));
      }
      if (r.result!.webhookEnabled != null) {
        extras.add(OTel.attributeBool(
          'tally.webhook.enabled',
          r.result!.webhookEnabled!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Tally HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
