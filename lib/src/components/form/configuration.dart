import 'package:nocterm/nocterm.dart';
import 'package:serverpod_tui/src/components/checkbox.dart';
import 'package:serverpod_tui/src/components/radio_button.dart';
import 'package:serverpod_tui/src/components/text.dart';
import 'package:serverpod_tui/src/components/wrap.dart';
import 'package:serverpod_tui/src/form/config.dart';
import 'package:serverpod_tui/src/form/config_option.dart';
import 'package:serverpod_tui/src/form/state.dart';
import 'package:serverpod_tui/src/serverpod_theme.dart';

/// Renders a form configuration label and description wrapping [child].
class FormConfigurationLayout extends StatelessComponent {
  const FormConfigurationLayout({
    super.key,
    required this.config,
    required this.child,
  });

  final FormConfig config;
  final Component child;

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          config.label,
          style: const TextStyle(
            color: Color.defaultColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        child,
        if (config.description case final FormDescription description) ...[
          SizedBox(height: description.spacing),
          ServerpodTuiText(
            description.label,
            style: const TextStyle(
              color: Color.defaultColor,
              fontWeight: FontWeight.dim,
            ),
          ),
        ],
      ],
    );
  }
}

/// Renders the appropriate configuration widget based on [config]'s type.
class FormConfiguration extends StatelessComponent {
  const FormConfiguration({
    super.key,
    required this.state,
    required this.config,
    required this.focused,
    required this.rebuild,
    this.vertical = false,
    this.onFormInputSubmit,
    this.onFormInputArrowUp,
    this.onFormInputArrowDown,
  });

  final FormState state;
  final FormConfig config;
  final bool focused;
  final VoidCallback rebuild;

  /// Whether select options are listed vertically with a cursor on the
  /// focused option, instead of side by side.
  final bool vertical;

  /// Callback for when [LogicalKey.enter] is received on a focused text input.
  final VoidCallback? onFormInputSubmit;

  /// Callback for when [LogicalKey.arrowUp] is received on a focused text input.
  final VoidCallback? onFormInputArrowUp;

  /// Callback for when [LogicalKey.arrowDown] is received on a focused text input.
  final VoidCallback? onFormInputArrowDown;

  @override
  Component build(BuildContext context) {
    return switch (config) {
      FormInputConfig config => FormInputConfiguration(
        state: state,
        config: config,
        focused: focused,
        onTap: () {
          state.requestFocus(config);
          rebuild();
        },
        onSubmit: onFormInputSubmit,
        onArrowUp: onFormInputArrowUp,
        onArrowDown: onFormInputArrowDown,
      ),
      FormSelectionConfig config => _buildFormSelectionConfig(config),
    };
  }

  Component _buildFormSelectionConfig(FormSelectionConfig config) {
    if (config.multiSelect) {
      return FormMultiSelectConfiguration(
        state: state,
        config: config,
        focused: focused,
        rebuild: rebuild,
        vertical: vertical,
      );
    }

    if (config.isBoolean) {
      return FormBooleanConfiguration(
        state: state,
        config: config,
        focused: focused,
        rebuild: rebuild,
        vertical: vertical,
      );
    }

    return FormSingleSelectConfiguration(
      state: state,
      config: config,
      focused: focused,
      rebuild: rebuild,
      vertical: vertical,
    );
  }
}

/// A text input configuration rendered as a [TextField].
class FormInputConfiguration extends StatelessComponent {
  const FormInputConfiguration({
    super.key,
    required this.state,
    required this.config,
    required this.focused,
    required this.onTap,
    this.onSubmit,
    this.onArrowUp,
    this.onArrowDown,
  });

  final FormState state;
  final FormInputConfig config;
  final bool focused;
  final VoidCallback onTap;

  /// Callback for when [LogicalKey.enter] is received while text input is focused.
  final VoidCallback? onSubmit;

  /// Callback for when [LogicalKey.arrowUp] is received while text input is focused..
  final VoidCallback? onArrowUp;

  /// Callback for when [LogicalKey.arrowDown] is received while text input is focused.
  final VoidCallback? onArrowDown;

  @override
  Component build(BuildContext context) {
    final theme = ServerpodTheme.of(context);
    final controller = state.getInputControllerFor(config);
    if (controller == null) return const SizedBox.shrink();

    return FormConfigurationLayout(
      config: config,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: controller.error,
                  builder: (context, error, child) {
                    final border = BoxBorder.all(
                      color: error != null
                          ? theme.errorLevel
                          : Color.fromRGB(255, 255, 255),
                    );

                    return TextField(
                      maxLines: config.maxLines,
                      width: config.width,
                      controller: controller,
                      focused: focused,
                      cursorBlinkRate: Duration(milliseconds: 700),
                      decoration: InputDecoration(
                        border: border,
                        focusedBorder: border,
                      ),
                      onKeyEvent: (event) {
                        switch (event.logicalKey) {
                          case LogicalKey.enter:
                            onSubmit?.call();
                            return onSubmit != null;
                          case LogicalKey.arrowUp:
                            onArrowUp?.call();
                            return onArrowUp != null;
                          case LogicalKey.arrowDown:
                            onArrowDown?.call();
                            return onArrowDown != null;
                        }
                        return false;
                      },
                    );
                  },
                ),
                if (config.suffixText case final suffix?)
                  Padding(
                    padding: EdgeInsets.only(top: config.maxLines / 2),
                    child: Text(
                      suffix,
                      style: const TextStyle(color: Colors.gray),
                    ),
                  ),
              ],
            ),
            ValueListenableBuilder<String?>(
              valueListenable: controller.error,
              builder: (context, error, child) {
                if (error case final message?) {
                  return Text(
                    message,
                    style: TextStyle(color: theme.errorLevel),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single-select configuration rendered as radio buttons.
class FormSingleSelectConfiguration extends StatelessComponent {
  const FormSingleSelectConfiguration({
    super.key,
    required this.state,
    required this.config,
    required this.focused,
    required this.rebuild,
    this.vertical = false,
  });

  final FormState state;
  final FormSelectionConfig config;
  final bool focused;
  final VoidCallback rebuild;

  /// See [FormConfiguration.vertical].
  final bool vertical;

  @override
  Component build(BuildContext context) {
    final selectedOption = state.getSelectedOptionFor(config);
    final focusedOptionIndex = state.getFocusedOptionIndexFor(config);

    return FormConfigurationLayout(
      config: config,
      child: _OptionList(
        vertical: vertical,
        children: [
          for (final option in config.options.indexed)
            _FormOptionRadio(
              option: option.$2,
              showCursor: vertical,
              focused: focused && focusedOptionIndex == option.$1,
              selected: selectedOption == option.$2,
              onTap: () {
                state.updateSelectedOption(config, option.$2);
                rebuild();
              },
            ),
        ],
      ),
    );
  }
}

/// A boolean configuration rendered as a single checkbox.
class FormBooleanConfiguration extends StatelessComponent {
  const FormBooleanConfiguration({
    super.key,
    required this.state,
    required this.config,
    required this.focused,
    required this.rebuild,
    this.vertical = false,
  });

  final FormState state;
  final FormSelectionConfig config;
  final bool focused;
  final VoidCallback rebuild;

  /// See [FormConfiguration.vertical].
  final bool vertical;

  @override
  Component build(BuildContext context) {
    final selectedOption =
        state.getSelectedOptionFor(config) as BoolFormConfigOption?;
    const defaultOption = BoolFormConfigOption.enabled;

    return FormConfigurationLayout(
      config: config,
      child: _FormOptionCheckbox(
        option: BoolFormConfigOption.enabled,
        showCursor: vertical,
        focused: focused,
        selected: selectedOption == defaultOption,
        onTap: () {
          final newOption = selectedOption == BoolFormConfigOption.enabled
              ? BoolFormConfigOption.disabled
              : BoolFormConfigOption.enabled;
          state.updateSelectedOption(config, newOption);
          rebuild();
        },
      ),
    );
  }
}

/// A multi-select configuration rendered as checkboxes.
class FormMultiSelectConfiguration extends StatelessComponent {
  const FormMultiSelectConfiguration({
    super.key,
    required this.state,
    required this.config,
    required this.focused,
    required this.rebuild,
    this.vertical = false,
  });

  final FormState state;
  final FormSelectionConfig config;
  final bool focused;
  final VoidCallback rebuild;

  /// See [FormConfiguration.vertical].
  final bool vertical;

  @override
  Component build(BuildContext context) {
    final selectedOptions = state.getSelectedOptionsFor(config) ?? {};
    final focusedOptionIndex = state.getFocusedOptionIndexFor(config);

    return FormConfigurationLayout(
      config: config,
      child: _OptionList(
        vertical: vertical,
        children: [
          for (final option in config.options.indexed)
            _FormOptionCheckbox(
              option: option.$2,
              showCursor: vertical,
              focused: focused && focusedOptionIndex == option.$1,
              selected: selectedOptions.contains(option.$2),
              onTap: () {
                state.updateSelectedOption(config, option.$2);
                rebuild();
              },
            ),
        ],
      ),
    );
  }
}

/// A single radio button option.
class _FormOptionRadio extends StatelessComponent {
  const _FormOptionRadio({
    required this.option,
    required this.showCursor,
    required this.focused,
    required this.selected,
    required this.onTap,
  });

  final FormConfigOption option;
  final bool showCursor;
  final bool focused;
  final bool selected;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _OptionRow(
        showCursor: showCursor,
        focused: focused,
        child: RadioButton(
          label: option.label,
          value: selected,
          focused: focused,
        ),
      ),
    );
  }
}

/// A single checkbox option.
class _FormOptionCheckbox extends StatelessComponent {
  const _FormOptionCheckbox({
    required this.option,
    required this.showCursor,
    required this.focused,
    required this.selected,
    required this.onTap,
  });

  final FormConfigOption option;
  final bool showCursor;
  final bool focused;
  final bool selected;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _OptionRow(
        showCursor: showCursor,
        focused: focused,
        child: Checkbox(
          label: option.label,
          value: selected,
          focused: focused,
        ),
      ),
    );
  }
}

/// Lists options vertically, or side by side when not [vertical].
class _OptionList extends StatelessComponent {
  const _OptionList({required this.vertical, required this.children});

  final bool vertical;
  final List<Component> children;

  @override
  Component build(BuildContext context) {
    if (!vertical) return Wrap(spacing: 2, children: children);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// An option, with a cursor in front of it when focused if [showCursor].
class _OptionRow extends StatelessComponent {
  const _OptionRow({
    required this.showCursor,
    required this.focused,
    required this.child,
  });

  final bool showCursor;
  final bool focused;
  final Component child;

  @override
  Component build(BuildContext context) {
    if (!showCursor) return child;

    final theme = ServerpodTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          focused ? '❯' : ' ',
          style: TextStyle(
            color: theme.activationKey,
            fontWeight: FontWeight.bold,
          ),
        ),
        child,
      ],
    );
  }
}
