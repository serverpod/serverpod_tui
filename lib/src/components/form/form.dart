import 'package:nocterm/nocterm.dart';
import 'package:serverpod_tui/src/components/form/configuration.dart';
import 'package:serverpod_tui/src/components/form/multi_screen_form.dart';
import 'package:serverpod_tui/src/form/state.dart';

/// A form component that renders text input,
/// single select, boolean and multi-select options.
class Form extends StatelessComponent {
  const Form({
    super.key,
    required this.state,
    required this.scrollController,
    required this.rebuild,
    this.spacing = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 1),
    this.onSubmit,
  });

  /// Creates a [Form] configured for multi-screen navigation.
  /// Each config is shown on its own screen, below the answers so far.
  /// Requires [MultiScreenFormState] to be used as the state.
  const factory Form.multiScreen({
    Key? key,
    required MultiScreenFormState state,
    required ScrollController scrollController,
    required VoidCallback rebuild,
    double spacing,
    EdgeInsets padding,
    VoidCallback? onSubmit,
    String? summaryDescription,
  }) = MultiScreenForm;

  final FormState state;
  final ScrollController scrollController;
  final VoidCallback rebuild;
  final double spacing;
  final EdgeInsets padding;

  /// Called when Enter is pressed while a text input is focused.
  final VoidCallback? onSubmit;

  @override
  Component build(BuildContext context) {
    final configurations = state.configurations;

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final config in configurations.indexed) ...[
                FormConfiguration(
                  state: state,
                  config: config.$2,
                  focused: config.$1 == state.focusedConfigIndex,
                  rebuild: rebuild,
                  onFormInputSubmit: onSubmit,
                  onFormInputArrowUp: () {
                    state.updateFocusedConfig(-1);
                    if (state.focusedConfigIndex ==
                        state.maxFocusedConfigIndex) {
                      scrollController.scrollToEnd();
                    } else {
                      scrollController.scrollUp(3);
                    }
                    rebuild();
                  },
                  onFormInputArrowDown: () {
                    state.updateFocusedConfig(1);
                    if (state.focusedConfigIndex == 0) {
                      scrollController.scrollToStart();
                    } else {
                      scrollController.scrollDown(3);
                    }
                    rebuild();
                  },
                ),
                SizedBox(height: spacing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
