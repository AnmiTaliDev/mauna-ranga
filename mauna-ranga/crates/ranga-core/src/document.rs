use crate::inline::{Run, visible_runs};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct ByteRange {
    pub start: usize,
    pub end: usize,
}

impl ByteRange {
    pub fn new(start: usize, end: usize) -> Self {
        ByteRange { start, end }
    }

    pub fn len(&self) -> usize {
        self.end - self.start
    }

    pub fn is_empty(&self) -> bool {
        self.start == self.end
    }

    pub fn contains(&self, other: ByteRange) -> bool {
        self.start <= other.start && other.end <= self.end
    }

    pub(crate) fn shift(&mut self, delta: isize) {
        self.start = self
            .start
            .checked_add_signed(delta)
            .expect("range start stays in bounds");
        self.end = self
            .end
            .checked_add_signed(delta)
            .expect("range end stays in bounds");
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ElementKind {
    SceneHeading {
        number: Option<String>,
    },
    Action,
    Character {
        extension: Option<String>,
        dual: bool,
    },
    Dialogue,
    Parenthetical,
    Transition,
    Centered,
    PageBreak,
    Section {
        level: u8,
    },
    Synopsis,
    Note,
    Boneyard,
    Lyric,
}

impl ElementKind {
    pub fn is_printed(&self) -> bool {
        !matches!(
            self,
            ElementKind::Section { .. }
                | ElementKind::Synopsis
                | ElementKind::Note
                | ElementKind::Boneyard
        )
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InlineKind {
    Bold,
    Italic,
    Underline,
    Marker,
    Note,
    Boneyard,
}

impl InlineKind {
    pub fn is_hidden(&self) -> bool {
        matches!(
            self,
            InlineKind::Marker | InlineKind::Note | InlineKind::Boneyard
        )
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Inline {
    pub kind: InlineKind,
    pub range: ByteRange,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Element {
    pub kind: ElementKind,
    pub range: ByteRange,
    pub inlines: Vec<Inline>,
    pub words: u32,
}

impl Element {
    pub fn runs(&self, source: &str) -> Vec<Run> {
        visible_runs(source, self.range, &self.inlines)
    }

    pub(crate) fn shift(&mut self, delta: isize) {
        self.range.shift(delta);
        for inline in &mut self.inlines {
            inline.range.shift(delta);
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TitleValue {
    pub range: ByteRange,
    pub inlines: Vec<Inline>,
}

impl TitleValue {
    pub fn runs(&self, source: &str) -> Vec<Run> {
        visible_runs(source, self.range, &self.inlines)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TitleEntry {
    pub key: String,
    pub values: Vec<TitleValue>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TitlePage {
    pub range: ByteRange,
    pub entries: Vec<TitleEntry>,
    pub words: u32,
}

impl TitlePage {
    pub fn entry(&self, key: &str) -> Option<&TitleEntry> {
        self.entries
            .iter()
            .find(|entry| entry.key.eq_ignore_ascii_case(key))
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Document {
    pub(crate) source: String,
    pub(crate) title_page: Option<TitlePage>,
    pub(crate) elements: Vec<Element>,
    pub(crate) word_count: u32,
}

impl Document {
    pub fn source(&self) -> &str {
        &self.source
    }

    pub fn text(&self, range: ByteRange) -> &str {
        &self.source[range.start..range.end]
    }

    pub fn title_page(&self) -> Option<&TitlePage> {
        self.title_page.as_ref()
    }

    pub fn elements(&self) -> &[Element] {
        &self.elements
    }

    pub fn word_count(&self) -> u32 {
        self.word_count
    }
}
