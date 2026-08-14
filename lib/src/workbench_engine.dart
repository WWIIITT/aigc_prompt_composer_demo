import 'dart:convert';

import 'package:aigc_prompt_composer/aigc_prompt_composer.dart';

enum PromptDemoKind { image, video }

extension PromptDemoKindLabel on PromptDemoKind {
  String get label => switch (this) {
    PromptDemoKind.image => 'Image prompt',
    PromptDemoKind.video => 'Video prompt',
  };

  String get description => switch (this) {
    PromptDemoKind.image =>
      'Compose a subject, environment, camera, light, and visual style.',
    PromptDemoKind.video =>
      'Compose a subject, shot, motion, timing, and sound direction.',
  };
}

enum TraceState { passed, notice, blocked }

final class WorkbenchTraceStep {
  const WorkbenchTraceStep({
    required this.label,
    required this.detail,
    required this.state,
  });

  final String label;
  final String detail;
  final TraceState state;
}

final class WorkbenchInput {
  const WorkbenchInput({
    required this.kind,
    required this.locale,
    required this.subject,
    required this.setting,
    required this.durationSeconds,
    required this.includeDuplicate,
    required this.includeConflict,
    required this.omitRequiredSection,
  });

  final PromptDemoKind kind;
  final String locale;
  final String subject;
  final String setting;
  final int durationSeconds;
  final bool includeDuplicate;
  final bool includeConflict;
  final bool omitRequiredSection;
}

final class WorkbenchRun {
  const WorkbenchRun({
    required this.prompt,
    required this.plainText,
    required this.structuredJson,
    required this.roundTripPassed,
    required this.strictCompositionPassed,
    required this.trace,
  });

  final ComposedPrompt prompt;
  final String plainText;
  final String structuredJson;
  final bool roundTripPassed;
  final bool strictCompositionPassed;
  final List<WorkbenchTraceStep> trace;
}

/// Creates provider-neutral scenarios that exercise the published package API.
final class PromptWorkbenchEngine {
  const PromptWorkbenchEngine();

  WorkbenchRun compose(WorkbenchInput input) {
    final scenario = switch (input.kind) {
      PromptDemoKind.image => _imageScenario(input),
      PromptDemoKind.video => _videoScenario(input),
    };

    final schema = PromptSchema.fromJson(scenario.schema.toJson());
    final recipe = PromptRecipe.fromJson(scenario.recipe.toJson());
    final options = PromptCompositionOptions.fromJson(
      scenario.options.toJson(),
    );
    final composer = PromptComposer();
    final prompt = composer.compose(
      schema: schema,
      recipe: recipe,
      options: options,
    );

    var strictCompositionPassed = true;
    try {
      composer.composeOrThrow(schema: schema, recipe: recipe, options: options);
    } on PromptCompositionException {
      strictCompositionPassed = false;
    }

    final plainText = const PlainTextPromptRenderer().render(prompt);
    final structuredJson = const StructuredJsonPromptRenderer().encode(
      prompt,
      pretty: true,
    );
    final restoredPrompt = ComposedPrompt.fromJson(prompt.toJson());
    final roundTripPassed =
        _sameJson(schema.toJson(), scenario.schema.toJson()) &&
        _sameJson(recipe.toJson(), scenario.recipe.toJson()) &&
        _sameJson(options.toJson(), scenario.options.toJson()) &&
        _sameJson(restoredPrompt.toJson(), prompt.toJson());

    return WorkbenchRun(
      prompt: prompt,
      plainText: plainText,
      structuredJson: structuredJson,
      roundTripPassed: roundTripPassed,
      strictCompositionPassed: strictCompositionPassed,
      trace: _traceFor(prompt, roundTripPassed, plainText),
    );
  }

  List<WorkbenchTraceStep> _traceFor(
    ComposedPrompt prompt,
    bool roundTripPassed,
    String plainText,
  ) {
    final usedFallback = prompt.issues.any(
      (issue) => issue.code == PromptIssueCodes.localeFallbackUsed,
    );
    final deduplicated = prompt.issues.any(
      (issue) => issue.code == PromptIssueCodes.fragmentDeduplicated,
    );
    final fragmentCount = prompt.sections.fold<int>(
      0,
      (count, section) => count + section.fragments.length,
    );

    return <WorkbenchTraceStep>[
      WorkbenchTraceStep(
        label: 'SCHEMA',
        detail: '${prompt.sections.length} sections',
        state: TraceState.passed,
      ),
      WorkbenchTraceStep(
        label: 'LOCALE',
        detail: usedFallback ? '${prompt.locale} → fallback' : prompt.locale,
        state: usedFallback ? TraceState.notice : TraceState.passed,
      ),
      WorkbenchTraceStep(
        label: 'ORDER',
        detail: '$fragmentCount fragments',
        state: TraceState.passed,
      ),
      WorkbenchTraceStep(
        label: 'DEDUPE',
        detail: deduplicated ? 'duplicate removed' : 'no duplicates',
        state: deduplicated ? TraceState.notice : TraceState.passed,
      ),
      WorkbenchTraceStep(
        label: 'VALIDATE',
        detail: prompt.hasErrors
            ? '${prompt.errorIssues.length} blocked'
            : '${prompt.warningIssues.length} warnings',
        state: prompt.hasErrors
            ? TraceState.blocked
            : prompt.warningIssues.isEmpty
            ? TraceState.passed
            : TraceState.notice,
      ),
      WorkbenchTraceStep(
        label: 'RENDER',
        detail: '${plainText.length} chars',
        state: roundTripPassed ? TraceState.passed : TraceState.blocked,
      ),
    ];
  }

  _Scenario _imageScenario(WorkbenchInput input) {
    final schema = PromptSchema(
      id: 'demo.image',
      version: '1',
      defaultLocale: 'en',
      fallbackLocales: const <String>['en'],
      sections: <PromptSectionDefinition>[
        PromptSectionDefinition(
          id: 'style',
          order: 50,
          localizedHeaders: const <String, String>{
            'en': 'Visual style',
            'zh-Hant': '視覺風格',
          },
          fragmentSeparator: ', ',
        ),
        PromptSectionDefinition(
          id: 'subject',
          order: 10,
          required: true,
          allowMultiple: false,
          localizedHeaders: const <String, String>{
            'en': 'Subject',
            'zh-Hant': '主體',
          },
        ),
        PromptSectionDefinition(
          id: 'environment',
          order: 20,
          required: true,
          localizedHeaders: const <String, String>{
            'en': 'Environment',
            'zh-Hant': '環境',
          },
        ),
        PromptSectionDefinition(
          id: 'camera',
          order: 30,
          localizedHeaders: const <String, String>{
            'en': 'Camera',
            'zh-Hant': '鏡頭',
          },
        ),
        PromptSectionDefinition(
          id: 'light',
          order: 40,
          localizedHeaders: const <String, String>{
            'en': 'Light',
            'zh-Hant': '光線',
          },
        ),
      ],
    );

    final subject = PromptFragment(
      id: 'subject.primary',
      sectionId: 'subject',
      localizedContent: const <String, String>{
        'en': '{{subject}}, clear silhouette and expressive detail.',
        'zh-Hant': '{{subject}}，輪廓清晰，細節富有表現力。',
      },
    );
    final fragments = <PromptFragment>[
      PromptFragment(
        id: 'light.soft',
        sectionId: 'light',
        localizedContent: const <String, String>{
          'en': 'Soft directional light with controlled highlights.',
          'zh-Hant': '柔和定向光，精準控制高光。',
        },
      ),
      PromptFragment(
        id: 'style.photoreal',
        sectionId: 'style',
        localizedContent: const <String, String>{
          'en': 'Photoreal editorial finish',
          'zh-Hant': '寫實編輯攝影質感',
        },
        conflictsWithFragmentIds: input.includeConflict
            ? const <String>['style.graphic']
            : const <String>[],
      ),
      PromptFragment(
        id: 'environment.primary',
        sectionId: 'environment',
        localizedContent: const <String, String>{
          'en': 'Set in {{setting}}, with coherent spatial depth.',
          'zh-Hant': '場景位於{{setting}}，空間層次連貫。',
        },
      ),
      if (!input.omitRequiredSection) subject,
      PromptFragment(
        id: 'camera.medium-wide',
        sectionId: 'camera',
        localizedContent: const <String, String>{
          'en': 'Medium-wide composition, natural perspective.',
          'zh-Hant': '中廣角構圖，自然透視。',
        },
      ),
      if (input.includeConflict)
        PromptFragment(
          id: 'style.graphic',
          sectionId: 'style',
          localizedContent: const <String, String>{
            'en': 'Flat graphic illustration',
            'zh-Hant': '平面圖像插畫風格',
          },
          conflictsWithFragmentIds: const <String>['style.photoreal'],
        ),
      if (input.includeDuplicate && !input.omitRequiredSection) subject,
    ];

    return _scenario(schema, fragments, input);
  }

  _Scenario _videoScenario(WorkbenchInput input) {
    final schema = PromptSchema(
      id: 'demo.video',
      version: '1',
      defaultLocale: 'en',
      fallbackLocales: const <String>['en'],
      sections: <PromptSectionDefinition>[
        PromptSectionDefinition(
          id: 'timing',
          order: 40,
          localizedHeaders: const <String, String>{
            'en': 'Timing',
            'zh-Hant': '節奏',
          },
        ),
        PromptSectionDefinition(
          id: 'subject',
          order: 10,
          required: true,
          allowMultiple: false,
          localizedHeaders: const <String, String>{
            'en': 'Subject',
            'zh-Hant': '主體',
          },
        ),
        PromptSectionDefinition(
          id: 'shot',
          order: 20,
          localizedHeaders: const <String, String>{
            'en': 'Shot',
            'zh-Hant': '鏡頭',
          },
        ),
        PromptSectionDefinition(
          id: 'motion',
          order: 30,
          required: true,
          localizedHeaders: const <String, String>{
            'en': 'Motion',
            'zh-Hant': '動作',
          },
        ),
        PromptSectionDefinition(
          id: 'sound',
          order: 50,
          localizedHeaders: const <String, String>{
            'en': 'Sound',
            'zh-Hant': '聲音',
          },
        ),
      ],
    );

    final subject = PromptFragment(
      id: 'subject.primary',
      sectionId: 'subject',
      localizedContent: const <String, String>{
        'en': '{{subject}} in {{setting}}.',
        'zh-Hant': '{{subject}}位於{{setting}}。',
      },
    );
    final trackingShot = PromptFragment(
      id: 'shot.tracking',
      sectionId: 'shot',
      localizedContent: const <String, String>{
        'en': 'A stable lateral tracking shot at eye level.',
        'zh-Hant': '視線高度的穩定橫向跟拍。',
      },
      conflictsWithFragmentIds: input.includeConflict
          ? const <String>['shot.handheld']
          : const <String>[],
    );
    final fragments = <PromptFragment>[
      PromptFragment(
        id: 'timing.duration',
        sectionId: 'timing',
        localizedContent: const <String, String>{
          'en': '{{duration}} seconds, one continuous readable action.',
          'zh-Hant': '{{duration}} 秒，單一連續且清楚可讀的動作。',
        },
      ),
      PromptFragment(
        id: 'motion.primary',
        sectionId: 'motion',
        localizedContent: const <String, String>{
          'en':
              'Wind drives the movement from left to right; motion remains physically coherent.',
          'zh-Hant': '風力推動動作由左至右發展，運動保持物理連貫。',
        },
      ),
      trackingShot,
      if (!input.omitRequiredSection) subject,
      PromptFragment(
        id: 'sound.ambient',
        sectionId: 'sound',
        localizedContent: const <String, String>{
          'en': 'Natural wind ambience, no dialogue.',
          'zh-Hant': '自然風聲環境音，無對白。',
        },
      ),
      if (input.includeConflict)
        PromptFragment(
          id: 'shot.handheld',
          sectionId: 'shot',
          localizedContent: const <String, String>{
            'en': 'Restless handheld camera shake.',
            'zh-Hant': '不穩定的手持鏡頭晃動。',
          },
          conflictsWithFragmentIds: const <String>['shot.tracking'],
        ),
      if (input.includeDuplicate && !input.omitRequiredSection) subject,
    ];

    return _scenario(schema, fragments, input);
  }

  _Scenario _scenario(
    PromptSchema schema,
    List<PromptFragment> fragments,
    WorkbenchInput input,
  ) {
    final variables = <String, Object?>{
      if (input.subject.trim().isNotEmpty) 'subject': input.subject.trim(),
      if (input.setting.trim().isNotEmpty) 'setting': input.setting.trim(),
      'duration': input.durationSeconds,
    };
    return _Scenario(
      schema: schema,
      recipe: PromptRecipe(
        schemaId: schema.id,
        schemaVersion: schema.version,
        fragments: fragments,
        variables: variables,
        metadata: const <String, Object?>{'source': 'android-demo'},
      ),
      options: PromptCompositionOptions(
        locale: input.locale,
        fallbackLocales: const <String>['en'],
        deduplication: FragmentDeduplication.byId,
        missingVariableBehavior: MissingVariableBehavior.preserve,
      ),
    );
  }
}

final class _Scenario {
  const _Scenario({
    required this.schema,
    required this.recipe,
    required this.options,
  });

  final PromptSchema schema;
  final PromptRecipe recipe;
  final PromptCompositionOptions options;
}

bool _sameJson(Object? first, Object? second) =>
    jsonEncode(first) == jsonEncode(second);
