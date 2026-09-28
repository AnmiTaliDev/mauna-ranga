# Mauna Ranga app

## About

Desktop Fountain screenplay editor. It uses the Mauna Ranga engine through `flutter_rust_bridge` and the widgets and theme of the `mauna` package.

## Dependencies

- Flutter 3.35 or newer (Dart 3.9 or newer)
- Rust toolchain, see [../mauna-ranga/README.md](../mauna-ranga/README.md)
- `mauna` 0.1, `flutter_rust_bridge` 2.13.0, `file_selector` 1.1
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

The toolbar has the File and View menus and the Settings button. Shortcuts are the same as in the `mauna` demo: Ctrl+K opens the command palette, Ctrl+B toggles the sidebar, Ctrl+, opens settings, Ctrl+Shift+F toggles focus mode, Escape leaves focus mode. Ctrl+O opens a file, Ctrl+S saves it, Ctrl+Shift+S saves it under a new name. A path passed on the command line is opened at start.

The sidebar lists sections and scene headings. The status bar shows words, pages and runtime from the engine. The panels dim while you type and return to full contrast when the pointer moves or the selection changes.

Files are opened, saved and exported through the system file dialog. Errors are shown in a `MaunaDialog`.

## Settings

Settings are stored in `$XDG_CONFIG_HOME/mauna-ranga/settings.json` (`~/.config/mauna-ranga/settings.json` by default, `%APPDATA%` on Windows, `~/Library/Application Support` on macOS):

- Theme preset and accent color
- Document font: Courier Prime or JetBrains Mono. The font is used in the editor and in PDF export. Courier Prime has no Cyrillic glyphs, so documents in Russian need JetBrains Mono.
- Screen minutes per page for the runtime estimate
- Dimming of the panels while typing

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
