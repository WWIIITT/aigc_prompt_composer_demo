import 'package:aigc_prompt_composer/aigc_prompt_composer.dart';
import 'package:aigc_prompt_composer_demo/src/workbench_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = PromptWorkbenchEngine();

  group('PromptWorkbenchEngine', () {
    test('composes a deterministic image prompt from the hosted API', () {
      final run = engine.compose(_input());

      expect(run.prompt.isValid, isTrue);
      expect(run.prompt.issues, isEmpty);
      expect(run.strictCompositionPassed, isTrue);
      expect(run.roundTripPassed, isTrue);
      expect(run.prompt.sections.map((section) => section.id), <String>[
        'subject',
        'environment',
        'camera',
        'light',
        'style',
      ]);
      expect(run.plainText, contains('A glass observatory'));
      expect(run.plainText, contains('a quiet basalt shore'));
      expect(run.structuredJson, contains('"formatVersion": 1'));
    });

    test('selects English through locale fallback and reports it', () {
      final run = engine.compose(_input(locale: 'fr-FR'));

      expect(run.prompt.isValid, isTrue);
      expect(run.plainText, contains('Subject'));
      expect(
        run.prompt.infoIssues.map((issue) => issue.code),
        contains(PromptIssueCodes.localeFallbackUsed),
      );
      expect(
        run.trace.singleWhere((step) => step.label == 'LOCALE').state,
        TraceState.notice,
      );
    });

    test('deduplicates repeated fragment ids and keeps a usable result', () {
      final run = engine.compose(_input(includeDuplicate: true));

      expect(run.prompt.isValid, isTrue);
      expect(run.strictCompositionPassed, isTrue);
      expect(
        run.prompt.issues.map((issue) => issue.code),
        containsAll(<String>[
          PromptIssueCodes.fragmentDeduplicated,
          PromptIssueCodes.duplicateFragmentId,
        ]),
      );
      expect(
        run.prompt.sections
            .singleWhere((section) => section.id == 'subject')
            .fragments,
        hasLength(1),
      );
    });

    test('surfaces a fragment conflict and blocks strict composition', () {
      final run = engine.compose(_input(includeConflict: true));

      expect(run.prompt.hasErrors, isTrue);
      expect(run.strictCompositionPassed, isFalse);
      expect(
        run.prompt.errorIssues.map((issue) => issue.code),
        contains(PromptIssueCodes.fragmentConflict),
      );
      expect(
        run.trace.singleWhere((step) => step.label == 'VALIDATE').state,
        TraceState.blocked,
      );
    });

    test('surfaces an omitted required section', () {
      final run = engine.compose(_input(omitRequiredSection: true));

      expect(run.prompt.hasErrors, isTrue);
      expect(
        run.prompt.errorIssues.map((issue) => issue.code),
        contains(PromptIssueCodes.requiredSectionMissing),
      );
    });

    test('composes localized video timing and motion sections', () {
      final run = engine.compose(
        _input(
          kind: PromptDemoKind.video,
          locale: 'zh-Hant',
          durationSeconds: 12,
        ),
      );

      expect(run.prompt.isValid, isTrue);
      expect(run.plainText, contains('12 秒'));
      expect(run.plainText, contains('動作'));
      expect(run.prompt.sections.map((section) => section.id), <String>[
        'subject',
        'shot',
        'motion',
        'timing',
        'sound',
      ]);
    });
  });
}

WorkbenchInput _input({
  PromptDemoKind kind = PromptDemoKind.image,
  String locale = 'en',
  int durationSeconds = 8,
  bool includeDuplicate = false,
  bool includeConflict = false,
  bool omitRequiredSection = false,
}) {
  return WorkbenchInput(
    kind: kind,
    locale: locale,
    subject: 'A glass observatory',
    setting: 'a quiet basalt shore',
    durationSeconds: durationSeconds,
    includeDuplicate: includeDuplicate,
    includeConflict: includeConflict,
    omitRequiredSection: omitRequiredSection,
  );
}
