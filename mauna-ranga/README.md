# Mauna Ranga engine

## About

Rust engine of Mauna Ranga, a Fountain screenplay editor. It parses Fountain, reparses edited parts of a document, paginates to the US screenplay format, counts words, pages and runtime, and exports PDF and Final Draft (FDX). It has no user interface.

## Dependencies

- Rust 1.88 or newer (edition 2024)
- `printpdf` 0.12 without default features, for PDF output
- `flutter_rust_bridge` 2.13.0, only in `ranga_ffi`

## Build

```sh
cargo build
cargo test
cargo clippy --all-targets
cargo fmt --check
```

## Crates

| Crate | Content |
|---|---|
| `ranga-core` | Document model, Fountain parser, incremental reparse, word count, outline |
| `ranga-layout` | Pagination, page geometry, runtime estimate |
| `ranga-export` | PDF and FDX export |
| `ranga_ffi` | API for the Flutter app, generated bindings in `app/lib/bridge/generated` |

## Parser

The grammar follows <https://fountain.io/syntax>. Rules that the spec leaves open:

- A line is blank when it is empty or holds only whitespace, except a line of exactly two spaces. That line joins dialogue and notes, as the spec describes.
- A title page is the first block of the file when every line is `Key: value` or an indented continuation (3 or more spaces, or a tab). Any key is accepted, so a file that starts with `Anything: text` is read as a title page.
- Forced markers (`!`, `@`, `.`, `>`, `~`, `#`, `=`) apply outside dialogue. Inside dialogue only parentheticals, lyrics and notes are recognized.
- A boneyard element starts at a line that begins with `/*`. A `/*` in the middle of a line is recognized only when `*/` closes it on the same line.
- Emphasis delimiters match only with a run of the same length, so `***bold italic***` works and mixed runs such as `***a* b**` stay literal.

## Incremental reparse

Fountain classification depends only on the blank-line separated block that holds a line, except for the title page and the boneyard. `Document::reparse_range` reparses the edited block and one block on each side, splices the result into the element list and shifts the ranges after it. When the old or the new text in that window contains `/*` or `*/`, or a boneyard element touches it, the whole document is parsed again. `ReparseInfo::full` reports which path was taken.

The word count lives in `ranga-core`, because each element keeps its own count and the document total changes by the difference for the reparsed elements. Pages and runtime come from `ranga-layout`, because they need pagination.

## Layout

Scene numbers written as `#n#` are printed on both sides of the heading. Column indents are the `ParagraphSpec` values of the Final Draft template in the sample `.fdx` files from fountain.io. Page size (US Letter), 1 inch top and bottom margins, 10 characters and 6 lines per inch are the common screenplay values and can be changed in `PageConfig`. One page is counted as one minute by default. The value is a parameter of `estimated_runtime_minutes`.

Known limitations:

- Dual dialogue is laid out as two consecutive blocks, not side by side.
- Action and dialogue break at line boundaries with at least two lines on each side, not at sentence boundaries.
- A dialogue block that continues on the next page gets `(MORE)` and `CHARACTER (CONT'D)`. Dialogue longer than one page is split several times.

## FDX

The output uses the element types, `Number`, `Alignment`, `Style` and `DualDialogue` structure found in the Brick & Steel and Big Fish samples on fountain.io. Two parts are not confirmed by those samples and need a check against a file saved by Final Draft:

- `StartsNewPage="Yes"` for page breaks. The samples only contain `"No"`.
- Lyrics are written as `Dialogue` inside a dialogue block and as `Action` elsewhere.

## Acknowledgments

- Fountain syntax by Stu Maschwitz and contributors, <https://fountain.io>
- `printpdf`, `flutter_rust_bridge`

## Documentation

- Fountain syntax: <https://fountain.io/syntax>
- Flutter app: [../app/README.md](../app/README.md)

## License

Apache License 2.0. See [LICENSE](../LICENSE).
