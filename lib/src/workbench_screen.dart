import 'package:aigc_prompt_composer/aigc_prompt_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'workbench_engine.dart';

enum _OutputView { plainText, structuredJson, diagnostics }

class WorkbenchScreen extends StatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  State<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends State<WorkbenchScreen> {
  static const _engine = PromptWorkbenchEngine();

  final _subjectController = TextEditingController(
    text: 'A glass greenhouse on a coastal cliff',
  );
  final _settingController = TextEditingController(
    text: 'blue hour after rain',
  );

  PromptDemoKind _kind = PromptDemoKind.image;
  String _locale = 'en';
  int _durationSeconds = 8;
  bool _includeDuplicate = false;
  bool _includeConflict = false;
  bool _omitRequiredSection = false;
  _OutputView _outputView = _OutputView.plainText;
  late WorkbenchRun _run;

  @override
  void initState() {
    super.initState();
    _run = _composeCurrent();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _settingController.dispose();
    super.dispose();
  }

  WorkbenchRun _composeCurrent() {
    return _engine.compose(
      WorkbenchInput(
        kind: _kind,
        locale: _locale,
        subject: _subjectController.text,
        setting: _settingController.text,
        durationSeconds: _durationSeconds,
        includeDuplicate: _includeDuplicate,
        includeConflict: _includeConflict,
        omitRequiredSection: _omitRequiredSection,
      ),
    );
  }

  void _compose() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _run = _composeCurrent());
  }

  void _selectKind(PromptDemoKind kind) {
    if (_kind == kind) return;
    setState(() {
      _kind = kind;
      if (kind == PromptDemoKind.image) {
        _subjectController.text = 'A glass greenhouse on a coastal cliff';
        _settingController.text = 'blue hour after rain';
      } else {
        _subjectController.text = 'A paper kite crossing a windy salt flat';
        _settingController.text = 'a wide open horizon';
      }
      _run = _composeCurrent();
    });
  }

  Future<void> _copyCurrentOutput() async {
    final value = switch (_outputView) {
      _OutputView.plainText => _run.plainText,
      _OutputView.structuredJson => _run.structuredJson,
      _OutputView.diagnostics =>
        _run.prompt.issues
            .map((issue) => '${issue.severity.name}: ${issue.code}')
            .join('\n'),
    };
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Current output copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const _WorkbenchHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    key: const Key('workbench-scroll'),
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth >= 720 ? 32 : 16,
                      20,
                      constraints.maxWidth >= 720 ? 32 : 16,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _TraceRail(steps: _run.trace),
                            const SizedBox(height: 20),
                            if (constraints.maxWidth >= 920)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(width: 390, child: _buildControls()),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildResults()),
                                ],
                              )
                            else ...<Widget>[
                              _buildControls(),
                              const SizedBox(height: 20),
                              _buildResults(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _PanelTitle(
              eyebrow: 'INPUT CONTRACT',
              title: 'Build a recipe',
              description:
                  'Change one condition at a time, then inspect the deterministic result.',
            ),
            const SizedBox(height: 20),
            const _FieldLabel('SCENARIO'),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ScenarioTile(
                    key: const Key('scenario-image'),
                    icon: Icons.image_outlined,
                    label: PromptDemoKind.image.label,
                    selected: _kind == PromptDemoKind.image,
                    onTap: () => _selectKind(PromptDemoKind.image),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScenarioTile(
                    key: const Key('scenario-video'),
                    icon: Icons.movie_creation_outlined,
                    label: PromptDemoKind.video.label,
                    selected: _kind == PromptDemoKind.video,
                    onTap: () => _selectKind(PromptDemoKind.video),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _FieldLabel('LOCALE'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('locale-$_locale'),
              initialValue: _locale,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.language),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'en', child: Text('English · en')),
                DropdownMenuItem(
                  value: 'zh-Hant',
                  child: Text('繁體中文 · zh-Hant'),
                ),
                DropdownMenuItem(
                  value: 'fr-FR',
                  child: Text('Fallback test · fr-FR'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _locale = value;
                  _run = _composeCurrent();
                });
              },
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('subject-field'),
              controller: _subjectController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Subject variable',
                prefixIcon: Icon(Icons.center_focus_strong),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('setting-field'),
              controller: _settingController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _compose(),
              decoration: const InputDecoration(
                labelText: 'Setting variable',
                prefixIcon: Icon(Icons.landscape_outlined),
              ),
            ),
            if (_kind == PromptDemoKind.video) ...<Widget>[
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  const Expanded(child: _FieldLabel('DURATION')),
                  Text(
                    '$_durationSeconds seconds',
                    key: const Key('duration-value'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Slider(
                key: const Key('duration-slider'),
                value: _durationSeconds.toDouble(),
                min: 4,
                max: 16,
                divisions: 6,
                label: '$_durationSeconds s',
                onChanged: (value) {
                  setState(() => _durationSeconds = value.round());
                },
                onChangeEnd: (_) => _compose(),
              ),
            ],
            const SizedBox(height: 18),
            const _FieldLabel('REGRESSION SWITCHES'),
            const SizedBox(height: 6),
            _RegressionSwitch(
              key: const Key('duplicate-switch'),
              title: 'Inject duplicate',
              subtitle: 'Expect deterministic by-id deduplication.',
              value: _includeDuplicate,
              onChanged: (value) {
                setState(() {
                  _includeDuplicate = value;
                  _run = _composeCurrent();
                });
              },
            ),
            _RegressionSwitch(
              key: const Key('conflict-switch'),
              title: 'Inject conflict',
              subtitle: 'Expect strict composition to be blocked.',
              value: _includeConflict,
              onChanged: (value) {
                setState(() {
                  _includeConflict = value;
                  _run = _composeCurrent();
                });
              },
            ),
            _RegressionSwitch(
              key: const Key('required-switch'),
              title: 'Omit required subject',
              subtitle: 'Expect a required-section error.',
              value: _omitRequiredSection,
              onChanged: (value) {
                setState(() {
                  _omitRequiredSection = value;
                  _run = _composeCurrent();
                });
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('compose-button'),
              onPressed: _compose,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('Compose prompt'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hosted dependency · aigc_prompt_composer 0.1.0-dev.3',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final prompt = _run.prompt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _PanelTitle(
                    eyebrow: 'COMPOSED OUTPUT',
                    title: prompt.isValid
                        ? 'Ready to render'
                        : 'Review required',
                    description: _kind.description,
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(
                  key: const Key('composition-status'),
                  label: prompt.isValid ? 'VALID' : 'BLOCKED',
                  color: prompt.isValid
                      ? WorkbenchColors.cyan
                      : WorkbenchColors.danger,
                  icon: prompt.isValid
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetricChip(
                  label: '${prompt.sections.length} sections',
                  icon: Icons.view_agenda_outlined,
                ),
                _MetricChip(
                  label: '${prompt.errorIssues.length} errors',
                  icon: Icons.error_outline,
                ),
                _MetricChip(
                  label: '${prompt.warningIssues.length} warnings',
                  icon: Icons.warning_amber_rounded,
                ),
                _MetricChip(
                  label: _run.roundTripPassed
                      ? 'JSON round trip'
                      : 'round trip failed',
                  icon: Icons.sync_alt,
                ),
                _MetricChip(
                  label: _run.strictCompositionPassed
                      ? 'strict accepted'
                      : 'strict blocked',
                  icon: Icons.gpp_good_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: WorkbenchColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WorkbenchColors.line),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _OutputTab(
                      key: const Key('output-plain-tab'),
                      label: 'Plain text',
                      selected: _outputView == _OutputView.plainText,
                      onTap: () =>
                          setState(() => _outputView = _OutputView.plainText),
                    ),
                  ),
                  Expanded(
                    child: _OutputTab(
                      key: const Key('output-json-tab'),
                      label: 'JSON',
                      selected: _outputView == _OutputView.structuredJson,
                      onTap: () => setState(
                        () => _outputView = _OutputView.structuredJson,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _OutputTab(
                      key: const Key('output-diagnostics-tab'),
                      label: 'Issues (${prompt.issues.length})',
                      selected: _outputView == _OutputView.diagnostics,
                      onTap: () =>
                          setState(() => _outputView = _OutputView.diagnostics),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 320),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: WorkbenchColors.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildOutputBody(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const Key('copy-output-button'),
                onPressed: _copyCurrentOutput,
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Copy current view'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputBody() {
    const codeStyle = TextStyle(
      color: Color(0xFFE8EEF5),
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.55,
    );
    return switch (_outputView) {
      _OutputView.plainText => SelectableText(
        _run.plainText,
        key: const Key('plain-output'),
        style: codeStyle,
      ),
      _OutputView.structuredJson => SelectableText(
        _run.structuredJson,
        key: const Key('json-output'),
        style: codeStyle,
      ),
      _OutputView.diagnostics => _DiagnosticsView(
        key: const Key('diagnostics-output'),
        issues: _run.prompt.issues,
      ),
    };
  }
}

class _WorkbenchHeader extends StatelessWidget {
  const _WorkbenchHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WorkbenchColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: WorkbenchColors.cyanBright,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: WorkbenchColors.ink,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'PROMPT WORKBENCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.25,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Android consumer verification for a pure Dart package',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFFAEBBD0), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const _HeaderBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF15223F),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFF2C3D60)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.circle, color: WorkbenchColors.cyanBright, size: 8),
          SizedBox(width: 7),
          Text(
            'PUB.DEV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceRail extends StatelessWidget {
  const _TraceRail({required this.steps});

  final List<WorkbenchTraceStep> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0F4F8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final columns = constraints.maxWidth >= 860
                ? 6
                : constraints.maxWidth >= 520
                ? 3
                : 2;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _FieldLabel('COMPOSITION TRACE'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    for (final step in steps)
                      SizedBox(
                        width: width,
                        child: _TraceStepCard(step: step),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TraceStepCard extends StatelessWidget {
  const _TraceStepCard({required this.step});

  final WorkbenchTraceStep step;

  @override
  Widget build(BuildContext context) {
    final color = switch (step.state) {
      TraceState.passed => WorkbenchColors.cyan,
      TraceState.notice => const Color(0xFFC37010),
      TraceState.blocked => WorkbenchColors.danger,
    };
    final icon = switch (step.state) {
      TraceState.passed => Icons.check_rounded,
      TraceState.notice => Icons.priority_high_rounded,
      TraceState.blocked => Icons.close_rounded,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WorkbenchColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            color: color,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 10, 11),
            child: Row(
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WorkbenchColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(eyebrow, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 5),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: WorkbenchColors.muted),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelMedium);
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? WorkbenchColors.cyan.withValues(alpha: 0.1)
                : WorkbenchColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? WorkbenchColors.cyan : WorkbenchColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                color: selected ? WorkbenchColors.cyan : WorkbenchColors.muted,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? WorkbenchColors.cyan : WorkbenchColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegressionSwitch extends StatelessWidget {
  const _RegressionSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: WorkbenchColors.muted,
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: WorkbenchColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WorkbenchColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: WorkbenchColors.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: WorkbenchColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputTab extends StatelessWidget {
  const _OutputTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x120B132B),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? WorkbenchColors.cyan : WorkbenchColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticsView extends StatelessWidget {
  const _DiagnosticsView({super.key, required this.issues});

  final List<PromptValidationIssue> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const Column(
        key: Key('no-diagnostics'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.verified_outlined, color: WorkbenchColors.cyanBright),
          SizedBox(height: 10),
          Text(
            'No diagnostics. This composition is clean.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFE8EEF5)),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[for (final issue in issues) _IssueRow(issue: issue)],
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final PromptValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final color = switch (issue.severity) {
      PromptIssueSeverity.info => WorkbenchColors.cyanBright,
      PromptIssueSeverity.warning => WorkbenchColors.orange,
      PromptIssueSeverity.error => const Color(0xFFFF7C8B),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF15223F),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${issue.severity.name.toUpperCase()} · ${issue.code}',
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            issue.message,
            style: const TextStyle(color: Color(0xFFE8EEF5), height: 1.4),
          ),
        ],
      ),
    );
  }
}
