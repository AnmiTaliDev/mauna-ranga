mod document;
mod incremental;
mod inline;
mod lines;
mod outline;
mod parser;

pub use document::{
    ByteRange, Document, Element, ElementKind, Inline, InlineKind, TitleEntry, TitlePage,
    TitleValue,
};
pub use incremental::{EditError, ReparseInfo, TextEdit};
pub use inline::{Run, plain_text, visible_runs};
pub use outline::{OutlineEntry, OutlineKind};
pub use parser::parse_full;
