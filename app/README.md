# Mauna Ranga app

## About

Desktop Fountain screenplay editor. It uses the Mauna Ranga engine through `flutter_rust_bridge` and the widgets and theme of the `mauna` package.

## Dependencies

- Flutter 3.35 or newer (Dart 3.9 or newer)
- Rust toolchain, see [../mauna-ranga/README.md](../mauna-ranga/README.md)
- `mauna` 0.1, `flutter_rust_bridge` 2.13.0, `file_selector` 1.1
- `flutter_localizations` (Flutter SDK) and `intl` 0.20, for the localized interface
- `flutter_rust_bridge_codegen` 2.13.0, only to regenerate bindings

## Build

```sh
flutter pub get
flutter analyze
flutter run -d linux
```

`flutter test` loads the engine from `../mauna-ranga/target/debug/libranga_ffi.so`. Build it first:

```sh
cargo build -p ranga_ffi --manifest-path ../mauna-ranga/Cargo.toml
flutter test
```

Regenerate the bindings after a change in `ranga-ffi/src/api`:

```sh
flutter_rust_bridge_codegen generate
```

## Usage

The toolbar has the File and View menus and the Settings button. The File menu opens, saves, imports FDX and exports to PDF, FDX, HTML and plain text, and lists the ten most recent files. The View menu holds the command palette, the sidebar, find and replace, statistics, scene moves and focus mode. Most menu commands are also in the command palette.

Shortcuts:

| Shortcut | Action |
|---|---|
| Ctrl+O, Ctrl+S, Ctrl+Shift+S | Open, save, save as |
| Ctrl+K | Command palette |
| Ctrl+B | Toggle the sidebar |
| Ctrl+, | Settings |
| Ctrl+F | Find and replace |
| Alt+Up, Alt+Down | Move the current scene up or down |
| Tab | Complete a character name or a scene location at the end of the line |
| Ctrl+Shift+F, Escape | Enter and leave focus mode |

A path passed on the command line is opened at start.

Tab completes only on a line that follows a blank line and holds no lowercase letters, or starts with a scene prefix such as `INT.`. Candidates come from the character names and scene locations already in the document, most frequent first. Pressing Tab again cycles through the matches.

Find and replace ignores case and has a whole word switch, so replacing `ST` with `STEEL` leaves `STELLA` alone. Replace all renames a character in the whole text. Statistics lists the speeches and dialogue words of every character. Notes lists every `[[note]]` of the document with its scene, and choosing one moves the caret there.

Moving a scene swaps it with the neighbouring scene. A scene does not move across a section heading.

An unsaved document is copied to `recovery.json` in the settings directory two seconds after the last edit. If the app starts and finds a copy that differs from the file on disk, it offers to restore it. Saving, opening a file and discarding remove the copy. There is one copy for the whole app, so two running instances overwrite each other.

The sidebar lists sections and scene headings. The status bar shows words, pages and runtime from the engine. The panels dim while you type and return to full contrast when the pointer moves or the selection changes.

On Linux the system window frame is off and the app draws its own title bar: the file name with a dot when there are unsaved changes, minimize, maximize and close buttons. Dragging the bar moves the window, a double click maximizes it, the window edges and corners resize it. Closing the window with unsaved changes asks to save, discard or cancel, whether the close comes from the button, Alt+F4 or the window manager: the runner holds the GTK `delete-event` and asks the app through `closeRequested`. The window operations go through the `mauna_ranga/window` method channel in `linux/runner/window_channel.cc`. On Windows and macOS the system frame stays.

Files are opened, saved and exported through the system file dialog. Errors are shown in a `MaunaDialog`.

## Settings

Settings are stored in `$XDG_CONFIG_HOME/mauna-ranga/settings.json` (`~/.config/mauna-ranga/settings.json` by default, `%APPDATA%` on Windows, `~/Library/Application Support` on macOS):

- Theme preset and accent color
- Document font: Courier Prime or JetBrains Mono. The font is used in the editor and in PDF export. Courier Prime has no Cyrillic glyphs, so documents in Russian need JetBrains Mono.
- Screen minutes per page for the runtime estimate
- Dimming of the panels while typing
- PDF export: title page on or off, page numbers on or off, a notes page on or off, watermark text
- The list of recent files

## Localization

The interface is available in English and Russian. The language is chosen in Settings, Editor, and follows the system language by default. Messages live in `lib/l10n/app_en.arb` (the template) and `lib/l10n/app_ru.arb`, and `flutter gen-l10n` turns them into `AppLocalizations` in `lib/l10n`. The generated files are committed. `flutter run` regenerates them when an ARB file changes, and `flutter gen-l10n` does it by hand.

To add a language, copy `app_en.arb` to `app_<code>.arb`, translate the values, and add an `AppLanguage` value with its `Locale` in `lib/settings/app_settings.dart` and its name in `lib/l10n/labels.dart`. `test/l10n_test.dart` checks that every locale has the same keys and placeholders as the template.

Not translated: error text that the engine produces, file dialog filter names (Fountain, Final Draft, PDF, HTML, Text), the `(MORE)` and `(CONT'D)` labels of the printed page, and key names in shortcuts. The title of the notes page in PDF export follows the interface language when the document font has Cyrillic glyphs (JetBrains Mono) and stays English with Courier Prime, which would print empty boxes.

## Editor highlighting

`MaunaDocumentCanvas` takes a `MaunaTextController`, so `FountainTextController` extends it and builds the text spans from the elements that the engine returns. Scene headings are bold. Transitions, sections, synopses, notes, boneyard and markup characters use `text.secondary`. Emphasis uses the bold, italic and underline faces of the document font. Layout indents of the printed page are not shown in the editor, and character names are shown as typed.

## Acknowledgments

- Courier Prime, JetBrains Mono and Inter (SIL OFL 1.1), license texts in `fonts/`
- Cargokit build scripts in `rust_builder/cargokit`, from `flutter_rust_bridge`

## Documentation

- Mauna HIG: <https://github.com/AnmiTaliDev/mauna-hig>
- `mauna` package: <https://github.com/AnmiTaliDev/mauna-ui>

## License

Apache License 2.0. See [LICENSE](../LICENSE).
