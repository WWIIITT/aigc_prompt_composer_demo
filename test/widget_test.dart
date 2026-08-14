import 'package:aigc_prompt_composer_demo/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lays out without exceptions on a compact Android viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PromptWorkbenchApp());
    await tester.pumpAndSettle();

    expect(find.text('PROMPT WORKBENCH'), findsOneWidget);
    final exception = tester.takeException() as FlutterError?;
    expect(exception, isNull, reason: exception?.toStringDeep());
  });

  testWidgets('renders a valid package composition on launch', (tester) async {
    await tester.pumpWidget(const PromptWorkbenchApp());
    await tester.pumpAndSettle();

    expect(find.text('PROMPT WORKBENCH'), findsOneWidget);
    expect(find.text('VALID'), findsOneWidget);
    expect(find.byKey(const Key('plain-output')), findsOneWidget);
    expect(_plainOutput(tester), contains('glass greenhouse'));
  });

  testWidgets('switches to the generic video scenario', (tester) async {
    await tester.pumpWidget(const PromptWorkbenchApp());
    await tester.pumpAndSettle();

    final video = find.byKey(const Key('scenario-video'));
    await tester.ensureVisible(video);
    await tester.tap(video);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('duration-slider')), findsOneWidget);
    expect(_plainOutput(tester), contains('paper kite'));
    expect(find.text('VALID'), findsOneWidget);
  });

  testWidgets('shows a strict validation failure in diagnostics', (
    tester,
  ) async {
    await tester.pumpWidget(const PromptWorkbenchApp());
    await tester.pumpAndSettle();

    final conflict = find.byKey(const Key('conflict-switch'));
    await tester.ensureVisible(conflict);
    await tester.tap(conflict);
    await tester.pumpAndSettle();

    expect(find.text('BLOCKED'), findsOneWidget);
    expect(find.text('strict blocked'), findsOneWidget);

    final diagnostics = find.byKey(const Key('output-diagnostics-tab'));
    await tester.ensureVisible(diagnostics);
    await tester.tap(diagnostics);
    await tester.pumpAndSettle();

    expect(find.textContaining('fragment_conflict'), findsOneWidget);
  });

  testWidgets('recomposes using edited variables', (tester) async {
    await tester.pumpWidget(const PromptWorkbenchApp());
    await tester.pumpAndSettle();

    final subject = find.byKey(const Key('subject-field'));
    await tester.ensureVisible(subject);
    await tester.enterText(subject, 'A mirrored weather station');

    final compose = find.byKey(const Key('compose-button'));
    await tester.ensureVisible(compose);
    await tester.tap(compose);
    await tester.pumpAndSettle();

    expect(_plainOutput(tester), contains('mirrored weather station'));
  });
}

String _plainOutput(WidgetTester tester) {
  return tester
          .widget<SelectableText>(find.byKey(const Key('plain-output')))
          .data ??
      '';
}
