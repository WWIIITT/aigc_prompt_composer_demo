import 'package:aigc_prompt_composer_demo/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('published package works through the Android UI', (tester) async {
    await tester.pumpWidget(const PromptWorkbenchApp());
    await tester.pumpAndSettle();

    expect(find.text('VALID'), findsOneWidget);

    final video = find.byKey(const Key('scenario-video'));
    await tester.ensureVisible(video);
    await tester.tap(video);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('duration-slider')), findsOneWidget);

    final duplicate = find.byKey(const Key('duplicate-switch'));
    await tester.ensureVisible(duplicate);
    await tester.tap(duplicate);
    await tester.pumpAndSettle();

    final diagnostics = find.byKey(const Key('output-diagnostics-tab'));
    await tester.ensureVisible(diagnostics);
    await tester.tap(diagnostics);
    await tester.pumpAndSettle();
    expect(find.textContaining('fragment_deduplicated'), findsOneWidget);

    final conflict = find.byKey(const Key('conflict-switch'));
    await tester.ensureVisible(conflict);
    await tester.tap(conflict);
    await tester.pumpAndSettle();
    expect(find.text('BLOCKED'), findsOneWidget);
    expect(find.textContaining('fragment_conflict'), findsOneWidget);
  });
}
