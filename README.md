# Mauna Ranga

## About

Fountain screenplay editor for writers who want a quiet interface. The repository holds the Rust engine and the Flutter desktop app.

## Dependencies

- Rust 1.88 or newer
- Flutter 3.32 or newer
- `mauna` package from pub.dev

## Build

```sh
cd mauna-ranga
cargo test
cd ../app
flutter pub get
flutter run -d linux
```

## Layout

| Directory | Content |
|---|---|
| `mauna-ranga/` | Rust engine: parser, pagination, export, FFI |
| `app/` | Flutter app |

## Acknowledgments

- Fountain syntax, <https://fountain.io>
- Mauna HIG and the `mauna` package

## Documentation

- Engine: [mauna-ranga/README.md](mauna-ranga/README.md)
- App: [app/README.md](app/README.md)

## License

Apache License 2.0. See [LICENSE](LICENSE).
