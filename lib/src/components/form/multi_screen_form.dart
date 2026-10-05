import 'package:nocterm/nocterm.dart';
import 'package:serverpod_tui/src/components/form/configuration.dart';
import 'package:serverpod_tui/src/components/form/form.dart';
import 'package:serverpod_tui/src/form/config.dart';
import 'package:serverpod_tui/src/form/state.dart';
import 'package:serverpod_tui/src/serverpod_theme.dart';

/// A multi screen form component that renders one config per screen,
/// with the answers given so far listed above it. The last screen lists
/// all answers with [summaryDescription] below them.
class MultiScreenForm extends Form {
  const MultiScreenForm({
    super.key,
    required this.state,
    required super.scrollController,
    required super.rebuild,
    super.spacing = 1,
    super.padding = const EdgeInsets.symmetric(horizontal: 1),
    super.onSubmit,
    this.summaryDescription,
  }) : super(state: state);

  /// State for multi screen form.
  final MultiScreenFormState state;

  /// Optional description for the summary screen.
  final String? summaryDescription;

  @override
  Component build(BuildContext context) {
    final answered = state.answeredConfigs;
    final config = state.currentConfig;

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // The child list keeps the same shape on every screen; nocterm
            // misplaces children that are inserted in front of existing ones.
            children: [
              _AnsweredConfigs(state: state, configs: answered),
              SizedBox(height: answered.isEmpty ? 0 : spacing),
              if (config != null)
                FormConfiguration(
                  state: state,
                  config: config,
                  focused: true,
                  rebuild: rebuild,
                  vertical: true,
                  onFormInputSubmit: onSubmit,
                  onFormInputArrowUp: () {
                    state.focusUp();
                    rebuild();
                  },
                  onFormInputArrowDown: () {
                    state.focusDown();
                    rebuild();
                  },
                )
              else if (summaryDescription case final description?)
                Text(
                  description,
                  style: const TextStyle(
                    color: Color.defaultColor,
                    fontWeight: FontWeight.dim,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The answers given so far, one line per config.
class _AnsweredConfigs extends StatelessComponent {
  const _AnsweredConfigs({required this.state, required this.configs});

  final MultiScreenFormState state;
  final List<FormConfig> configs;

  @override
  Component build(BuildContext context) {
    if (configs.isEmpty) return const SizedBox.shrink();

    final theme = ServerpodTheme.of(context);
    final labelWidth = configs
        .map((config) => config.label.length)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final config in configs)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✔ ', style: TextStyle(color: theme.success)),
              Text(
                '${config.label.padRight(labelWidth)}  ',
                style: const TextStyle(color: Color.defaultColor),
              ),
              Expanded(
                child: Text(
                  state.selectedLabelFor(config),
                  style: const TextStyle(
                    color: Color.defaultColor,
                    fontWeight: FontWeight.dim,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
