import 'package:nocterm/nocterm.dart' hide isEmpty;
import 'package:serverpod_tui/serverpod_tui.dart';
import 'package:test/test.dart';

import '../util.dart';

// --- Test configs ---

enum DatabaseOption implements FormConfigOption {
  postgres('Postgres'),
  sqlite('SQLite')
  ;

  const DatabaseOption(this.label);
  @override
  final String label;
}

enum SimpleConfig<T extends FormConfigOption>
    implements FormSelectionConfig<T> {
  database<DatabaseOption>(
    label: 'Database',
    options: DatabaseOption.values,
    defaultOptions: {DatabaseOption.postgres},
  ),
  auth<BoolFormConfigOption>(
    label: 'Authentication',
    options: BoolFormConfigOption.values,
    defaultOptions: {BoolFormConfigOption.enabled},
  )
  ;

  const SimpleConfig({
    required this.label,
    required this.options,
    required this.defaultOptions,
    this.requirements = const [],
    this.multiSelect = false,
    this.exclusiveOptions = const {},
    this.selectionRequired = false,
    this.description,
  });

  @override
  final String label;
  @override
  final List<T> options;
  @override
  final Set<T> defaultOptions;
  @override
  final List<FormRequirement> requirements;
  @override
  final bool multiSelect;
  @override
  final Set<T> exclusiveOptions;
  @override
  final bool selectionRequired;
  @override
  final FormDescription? description;
}

enum EditorOption implements FormConfigOption {
  vsCode('VS Code'),
  cursor('Cursor')
  ;

  const EditorOption(this.label);
  @override
  final String label;
}

class RequiredEditorConfig implements FormSelectionConfig<EditorOption> {
  const RequiredEditorConfig();

  @override
  String get label => 'Editors';
  @override
  List<EditorOption> get options => EditorOption.values;
  @override
  Set<EditorOption> get defaultOptions => const {};
  @override
  bool get multiSelect => true;
  @override
  bool get selectionRequired => true;
  @override
  Set<EditorOption> get exclusiveOptions => const {};
  @override
  List<FormRequirement> get requirements => const [];
  @override
  FormDescription? get description => null;
}

// --- Test app infrastructure ---

class _MultiScreenTestState extends TuiState {
  _MultiScreenTestState(this.formState);

  final MultiScreenFormState formState;

  @override
  final logHistory = BoundedQueueList<Object>(TestState.maxLogEntries);

  @override
  final Map<String, TrackedOperation> activeOperations = {};
}

class _MultiScreenTestHolder extends TuiAppStateHolder<_MultiScreenTestState> {
  _MultiScreenTestHolder(this._state);

  final _MultiScreenTestState _state;
  TuiAppState? _widgetState;

  @override
  _MultiScreenTestState get state => _state;

  @override
  TuiAppState? get widgetState => _widgetState;

  @override
  void attach(TuiAppState widgetState) {
    _widgetState = widgetState;
  }

  @override
  void detach(TuiAppState widgetState) {
    if (_widgetState == widgetState) _widgetState = null;
  }
}

class _MultiScreenTestApp extends TuiApp<_MultiScreenTestHolder> {
  const _MultiScreenTestApp({
    required super.holder,
    this.summaryDescription,
  });

  final String? summaryDescription;

  @override
  TuiAppState<_MultiScreenTestApp> createState() => _MultiScreenTestAppState();
}

/// Hosts the form with the key model of a sequential prompt: arrows move
/// the cursor, Space toggles, Enter confirms and continues, Escape goes back.
class _MultiScreenTestAppState extends TuiAppState<_MultiScreenTestApp> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Component buildApp(BuildContext context) {
    final formState = component.holder.state.formState;

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.isControlPressed ||
            event.isAltPressed ||
            event.isMetaPressed) {
          return false;
        }
        switch (event.logicalKey) {
          case LogicalKey.enter:
            if (formState.isSummary) return false;
            formState.confirmFocusedOption();
            formState.nextScreen();
          case LogicalKey.escape:
            formState.previousScreen();
          case LogicalKey.arrowUp:
            formState.focusUp();
          case LogicalKey.arrowDown:
            formState.focusDown();
          case LogicalKey.space:
            formState.onSelect();
          default:
            return false;
        }
        component.holder.markDirty();
        return true;
      },
      child: Form.multiScreen(
        state: formState,
        scrollController: _scrollController,
        rebuild: component.holder.markDirty,
        summaryDescription: component.summaryDescription,
      ),
    );
  }
}

// --- Helpers ---

Future<void> _sendKey(NoctermTester tester, LogicalKey key) {
  return tester.sendKeyEvent(KeyboardEvent(logicalKey: key));
}

Future<void> _pump(NoctermTester tester) {
  return tester.pump(const Duration(milliseconds: 100));
}

// --- Tests ---

void main() {
  group('Given a multi-screen form with multiple configs', () {
    late NoctermTester tester;
    late MultiScreenFormState state;
    late _MultiScreenTestHolder holder;

    setUp(() async {
      state = MultiScreenFormState(SimpleConfig.values);
      holder = _MultiScreenTestHolder(_MultiScreenTestState(state));
      tester = await NoctermTester.create(size: const Size(80, 24));
      await tester.pumpComponent(
        _MultiScreenTestApp(holder: holder, summaryDescription: 'All done.'),
      );
    });

    tearDown(() async {
      tester.dispose();
      await holder.dispose();
    });

    test(
      'when the first screen is shown, '
      'then the cursor is on the selected option and no answers are listed',
      () async {
        await _pump(tester);

        expect(state.currentConfig, SimpleConfig.database);
        expect(state.getFocusedOptionIndexFor(SimpleConfig.database), 0);
        expect(state.answeredConfigs, isEmpty);
        expect(tester.terminalState.getText(), isNot(contains('✔')));
      },
    );

    test(
      'when Enter is pressed on the first screen, '
      'then it advances to the next screen and lists the answer',
      () async {
        await _sendKey(tester, LogicalKey.enter);
        await _pump(tester);

        expect(state.currentScreenIndex, 1);
        expect(state.answeredConfigs, [SimpleConfig.database]);
        expect(tester.terminalState.getText(), contains('Database'));
        expect(tester.terminalState.getText(), contains('Postgres'));
      },
    );

    test(
      'when arrowDown is pressed and then Enter, '
      'then the option under the cursor is selected before advancing',
      () async {
        await _sendKey(tester, LogicalKey.arrowDown);
        await _pump(tester);
        expect(state.getFocusedOptionIndexFor(SimpleConfig.database), 1);

        await _sendKey(tester, LogicalKey.enter);
        await _pump(tester);

        expect(
          state.getSelectedOptionFor(SimpleConfig.database),
          DatabaseOption.sqlite,
        );
        expect(state.currentScreenIndex, 1);
      },
    );

    test(
      'when arrowUp is pressed on the first option, '
      'then the cursor wraps to the last option',
      () async {
        await _sendKey(tester, LogicalKey.arrowUp);
        await _pump(tester);

        expect(state.getFocusedOptionIndexFor(SimpleConfig.database), 1);
      },
    );

    test(
      'when Space is pressed on a boolean screen, '
      'then the option is toggled',
      () async {
        await _sendKey(tester, LogicalKey.enter);
        await _pump(tester);
        expect(state.currentConfig, SimpleConfig.auth);

        await _sendKey(tester, LogicalKey.space);
        await _pump(tester);

        expect(
          state.getSelectedOptionFor(SimpleConfig.auth),
          BoolFormConfigOption.disabled,
        );
      },
    );

    test(
      'when Escape is pressed on the first screen, '
      'then it stays on the first screen',
      () async {
        await _sendKey(tester, LogicalKey.escape);
        await _pump(tester);

        expect(state.currentScreenIndex, 0);
      },
    );

    test(
      'when Escape is pressed on a non-first screen, '
      'then it goes back and puts the cursor on the selected option',
      () async {
        await _sendKey(tester, LogicalKey.arrowDown);
        await _sendKey(tester, LogicalKey.enter);
        await _pump(tester);
        expect(state.currentScreenIndex, 1);

        await _sendKey(tester, LogicalKey.escape);
        await _pump(tester);

        expect(state.currentScreenIndex, 0);
        expect(state.getFocusedOptionIndexFor(SimpleConfig.database), 1);
      },
    );

    test(
      'when navigating through all screens, '
      'then the summary lists every answer with the description',
      () async {
        final configCount = state.configScreenCount;

        for (var i = 0; i < configCount; i++) {
          expect(state.isSummary, isFalse);
          expect(state.currentScreenIndex, i);
          await _sendKey(tester, LogicalKey.enter);
          await _pump(tester);
        }

        expect(state.isSummary, isTrue);
        expect(state.currentConfig, isNull);
        final screenText = tester.terminalState.getText();
        expect(screenText, contains('Database'));
        expect(screenText, contains('Postgres'));
        expect(screenText, contains('Authentication'));
        expect(screenText, contains('Enabled'));
        expect(screenText, contains('All done.'));
      },
    );
  });

  group('Given a multi-screen form with a single config', () {
    late NoctermTester tester;
    late MultiScreenFormState state;
    late _MultiScreenTestHolder holder;

    setUp(() async {
      state = MultiScreenFormState([SimpleConfig.database]);
      holder = _MultiScreenTestHolder(_MultiScreenTestState(state));
      tester = await NoctermTester.create(size: const Size(80, 24));
      await tester.pumpComponent(
        _MultiScreenTestApp(holder: holder),
      );
    });

    tearDown(() async {
      tester.dispose();
      await holder.dispose();
    });

    test('then hasSingleScreen is true', () {
      expect(state.hasSingleScreen, isTrue);
    });

    test(
      'when Enter is pressed, '
      'then the screen index does not change',
      () async {
        await _sendKey(tester, LogicalKey.enter);
        await _pump(tester);

        expect(state.currentScreenIndex, 0);
        expect(state.isSummary, isFalse);
      },
    );

    test(
      'when escape is pressed, '
      'then the screen index does not change',
      () async {
        await _sendKey(tester, LogicalKey.escape);
        await _pump(tester);

        expect(state.currentScreenIndex, 0);
        expect(state.isSummary, isFalse);
      },
    );
  });

  group(
    'Given a multi-screen form whose first config requires a selection',
    () {
      late NoctermTester tester;
      late MultiScreenFormState state;
      late _MultiScreenTestHolder holder;

      setUp(() async {
        state = MultiScreenFormState([
          const RequiredEditorConfig(),
          SimpleConfig.database,
        ]);
        holder = _MultiScreenTestHolder(_MultiScreenTestState(state));
        tester = await NoctermTester.create(size: const Size(80, 24));
        await tester.pumpComponent(
          _MultiScreenTestApp(holder: holder),
        );
      });

      tearDown(() async {
        tester.dispose();
        await holder.dispose();
      });

      test(
        'when Enter is pressed without a selection, '
        'then it stays on the first screen',
        () async {
          await _sendKey(tester, LogicalKey.enter);
          await _pump(tester);

          expect(state.canAdvance, isFalse);
          expect(state.currentScreenIndex, 0);
        },
      );

      test(
        'when an option is selected using Space key and Enter is pressed, '
        'then it advances to the next screen',
        () async {
          await _sendKey(tester, LogicalKey.space);
          await _pump(tester);

          await _sendKey(tester, LogicalKey.enter);
          await _pump(tester);

          expect(state.currentScreenIndex, 1);
        },
      );
    },
  );
}
