mod document;
mod incremental;
mod inline;
mod lines;
mod notes;
mod outline;
mod parser;
mod stats;

pub use document::{
    ByteRange, Document, Element, ElementKind, Inline, InlineKind, TitleEntry, TitlePage,
    TitleValue,
};
pub use incremental::{EditError, ReparseInfo, TextEdit};
pub use inline::{Run, plain_text, visible_runs};
pub use notes::NoteEntry;
pub use outline::{OutlineEntry, OutlineKind};
pub use parser::parse_full;
pub use stats::CharacterStat;
