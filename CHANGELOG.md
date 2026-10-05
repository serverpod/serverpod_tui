## 0.14.0

- **FEAT**: Multi screen forms are now sequential prompts. Options are listed vertically with a `❯` cursor, the answers given so far are listed above the current config, and the last screen lists every answer.
- **FEAT**: Added `FormConfiguration.vertical` to list select options vertically with a cursor. The single page `Form` keeps listing them side by side.
- **FEAT**: Added `MultiScreenFormState.currentConfig`, `answeredConfigs` and `confirmFocusedOption`, and `FormState.selectedLabelFor`.
- **BREAKING**: `MultiScreenForm` no longer renders Back/Next/Submit buttons. `backButtonActivationKey`, `nextButtonActivationKey` and `submitButtonLabel` are removed, along with `focusOnButton`, `focusedButtonIndex`, `focusBackButton` and `focusNextButton` on `MultiScreenFormState`. The host app handles Enter and Escape.
- **BREAKING**: `MultiScreenFormState.focusUp` and `focusDown` now move the cursor over the options of the current screen.

## 0.13.0

- **FEAT**: Multi screen forms can now require a selection before moving past a config (`selectionRequired`), and multi-select configs can mark options that can not be combined with others (`exclusiveOptions`).
- **FEAT**: Added `MultiScreenFormState.canAdvance`. The `Next`/`Submit` button is disabled while the current screen is missing a required selection.
- **BREAKING**: `FormSelectionConfig` implementers must add `exclusiveOptions` and `selectionRequired`.

## 0.12.0

- **FEAT**: The tab bar underline now matches the surrounding box border's color (the selection highlight keeps its accent) and merges into the border with junction characters (`┝`/`┥`) instead of leaving gaps.
- **FIX**: The underline no longer breaks one cell short of its end at fractional pane widths.

## 0.11.0

- **FEAT**: Upgrade to nocterm 0.9.0. Borders and dividers now merge into junction characters (`├ ┤ ┬ ┴ ┼`) where they meet, so `BorderedBox` and dividers join seamlessly instead of leaving gaps.

## 0.10.2

- **FIX**: Restore cursor when quiting TUI on iTerm.

## 0.10.1

- **FEAT**: Multi screen forms now auto-focus `Next` button on the summary screen to prioritise form submission.

## 0.10.0

- **BREAKING**: `ServerpodTerminalBackend`'s `preExit` now requires `exitCode`.

## 0.9.0

- **FEAT**: Added submit button to multi screen form.
- **FEAT**: Added `ServerpodTuiText` to render multi line texts without leading and trailing whitespace after the first line.
- **FIX**: Removed leading and trailing whitespace from multi line form description text.

## 0.8.0

- **FEAT**: `AlertLine` copy/dismiss hints are now clickable.
- **FEAT**: Copying an alert's segment now shows an inline green `✓ Copied` confirmation (matching the log's success mark) in place of the `C Copy` hint for a couple of seconds, instead of appending a `Copied to clipboard` line that displaced the content below it.
- **BREAKING**: `AlertLine` now requires `onCopy` and `onDismiss` callbacks and takes an optional `copied` flag.

## 0.7.0

- **FEAT**: Added per-tab status indicators to `TabBar` via a new `TabActivity` enum and `states` parameter, plus a reusable `TabActivityIndicator` widget: running (`●`), loading (spinner), stopped (`○`).
- **FIX**: Aligned the active operation (launch spinner) line flush-left with a single space so it matches the log text on both the server and Flutter tabs.
- **FIX**: Restyled `AlertLine` copy/dismiss hints to match the command bar (unbracketed, capitalized, command colors) and right-aligned them on the line.

## 0.6.0

- **FEAT**: Added multiple config options support for form requirement.
- **FIX**: Enabled scroll for multi form summary.
- **CHORE**: Marked `FormConfig` as sealed for exhaustive pattern matching.
- **CHORE**: Removed redundant "Tip" text from `Tip` component.

## 0.5.0

- **FEAT**: Improved `HelpOverlay` UI.
- **FEAT**: Improved spacing in `TabBar`.
- **CHORE**: Upgraded `nocterm` to `^0.8.0` (Windows input/path fixes, IME and layout fixes).

## 0.4.0

- **FIX**: Removed excessive whitespace from multi screen form summary.
- **FIX**: Added right padding to multi screen form navigation buttons.
- **FIX**: Removed `FormState.multiScreen` constructor which did not enforce the requirement of `MultiScreenFormState` by `Form.multiScreen`.

## 0.3.0

- **FEAT**: Added multi screen form support.
- **FIX**: Fixed form config requirements evaluation issue where reselecting a required config option did not bring back a previously constrained config.

## 0.2.1

- **FEAT**: Added alert messages. `TuiAppStateHolder.showAlert` pins a copyable alert (e.g. an email verification code) in the log panel via `AlertLine`; a `<...>`-marked segment is copied to the clipboard and re-copied with `C`, and `Esc` dismisses it.
- **FEAT**: Clipboard copies now use the native platform tool (`pbcopy`/`clip`/`wl-copy`/`xclip`/`xsel`) in addition to OSC 52, so copying works in terminals without OSC 52 support (e.g. macOS Terminal.app).

## 0.2.0

- **BREAKING** **FEAT**: Added support for optional description for form configurations.
- **FEAT**: Improved form UI
- **CHORE**: Replaced `serverpod_shared` dependency with `serverpod_logging`.

## 0.1.0-rc.6

- **FIX**: Fixed buttons activating on Ctrl, Alt, and Meta key combinations so app-level shortcuts reach their handlers.
- **FIX**: Fixed the Ctrl-C hint toggling remounting the whole app subtree and resetting its state.
- **FIX**: Fixed text selection getting swallowed up on Windows.

## 0.1.0-rc.5

- **FEAT**: Added support for form input validation and suffix text.

## 0.1.0-rc.4

- **FEAT**: Updated Ctrl-C behavior to match common CLI tools: copies the current selection if there is one, otherwise a first press arms exit and a second press within two seconds exits gracefully.

## 0.1.0-rc.3

- **CHORE**: Lowered minimum Dart SDK to 3.10.3

## 0.1.0-rc.2

- **FIX**: Fixed terminal restoration on Windows

## 0.1.0-rc.1

- Initial version.
