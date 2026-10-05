import 'package:nocterm/nocterm.dart';
import 'package:serverpod_tui/serverpod_tui.dart';
import 'package:test/test.dart';

enum _Database implements FormConfigOption {
  postgres('Postgres'),
  sqlite('SQLite')
  ;

  const _Database(this.label);
  @override
  final String label;
}

class _DatabaseConfig implements FormSelectionConfig<_Database> {
  const _DatabaseConfig();

  @override
  String get label => 'Database';
  @override
  List<_Database> get options => _Database.values;
  @override
  Set<_Database> get defaultOptions => const {_Database.postgres};
  @override
  bool get multiSelect => false;
  @override
  bool get selectionRequired => false;
  @override
  Set<_Database> get exclusiveOptions => const {};
  @override
  List<FormRequirement> get requirements => const [];
  @override
  FormDescription? get description => null;
}

/// The line of the rendered screen that contains [text].
String _lineWith(NoctermTester tester, String text) {
  return tester.terminalState
      .getText()
      .split('\n')
      .firstWhere((line) => line.contains(text));
}

void main() {
  group('Given a single-select config', () {
    late NoctermTester tester;
    late ScrollController scrollController;

    setUp(() async {
      tester = await NoctermTester.create(size: const Size(80, 24));
      scrollController = ScrollController();
    });

    tearDown(() {
      scrollController.dispose();
      tester.dispose();
    });

    test(
      'when rendered in a single page form, '
      'then the options are listed side by side without a cursor',
      () async {
        await tester.pumpComponent(
          Form(
            state: FormState(const [_DatabaseConfig()]),
            scrollController: scrollController,
            rebuild: () {},
          ),
        );

        expect(_lineWith(tester, 'Postgres'), contains('SQLite'));
        expect(tester.terminalState.getText(), isNot(contains('❯')));
      },
    );

    test(
      'when rendered in a multi screen form, '
      'then the options are listed vertically with a cursor on the first',
      () async {
        await tester.pumpComponent(
          Form.multiScreen(
            state: MultiScreenFormState(const [_DatabaseConfig()]),
            scrollController: scrollController,
            rebuild: () {},
          ),
        );

        expect(_lineWith(tester, 'Postgres'), isNot(contains('SQLite')));
        expect(_lineWith(tester, 'Postgres'), contains('❯'));
      },
    );
  });
}
