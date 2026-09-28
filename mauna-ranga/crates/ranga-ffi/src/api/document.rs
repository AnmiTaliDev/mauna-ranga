use std::sync::{Arc, Mutex};

use flutter_rust_bridge::frb;
use ranga_core::{Document, Element, ElementKind, InlineKind, OutlineKind, parse_full};
use ranga_layout::{PageConfig, estimated_runtime_minutes, paginate as layout_pages};

use crate::utf16::{Cursor, byte_offset, units};

#[frb(opaque)]
pub struct DocumentHandle {
    document: Mutex<Arc<Document>>,
}

impl DocumentHandle {
    pub(crate) fn current(&self) -> Result<Arc<Document>, String> {
        self.document
            .lock()
            .map(|document| Arc::clone(&document))
            .map_err(|_| STATE_LOST.to_string())
    }
}

const STATE_LOST: &str = "The document state was lost after an internal error. Reopen the file.";

pub struct TextEdit {
    pub start: u32,
    pub end: u32,
    pub replacement: String,
}

pub enum ElementType {
    SceneHeading,
    Action,
    Character,
    Dialogue,
    Parenthetical,
    Transition,
    Centered,
    PageBreak,
    Section,
    Synopsis,
    Note,
    Boneyard,
    Lyric,
}

pub enum SpanStyle {
    Bold,
    Italic,
    Underline,
    Marker,
    Note,
    Boneyard,
}

pub struct StyleSpan {
    pub style: SpanStyle,
    pub start: u32,
    pub end: u32,
}

pub struct ElementSnapshot {
    pub kind: ElementType,
    pub start: u32,
    pub end: u32,
    pub spans: Vec<StyleSpan>,
}

pub struct DocumentSnapshot {
    pub first: u32,
    pub removed: u32,
    pub inserted: Vec<ElementSnapshot>,
    pub shift: i64,
    pub title_page_end: Option<u32>,
    pub word_count: u32,
}

pub struct OutlineEntry {
    pub title: String,
    pub level: u8,
    pub offset: u32,
}

pub struct PageSettings {
    pub minutes_per_page: f32,
}

pub struct DocumentStats {
    pub words: u32,
    pub pages: u32,
    pub runtime_minutes: f32,
}

pub struct PageSnapshot {
    pub number: u32,
    pub first_element: u32,
    pub end_element: u32,
    pub lines: u32,
}

pub async fn create_document(source: String) -> DocumentHandle {
    DocumentHandle {
        document: Mutex::new(Arc::new(parse_full(&source))),
    }
}

#[frb(sync)]
pub fn document_snapshot(handle: &DocumentHandle) -> Result<DocumentSnapshot, String> {
    let document = handle.current()?;
    Ok(snapshot(&document, 0, 0, document.elements().len(), 0))
}

#[frb(sync)]
pub fn apply_edit(handle: &DocumentHandle, edit: TextEdit) -> Result<DocumentSnapshot, String> {
    let mut guard = handle.document.lock().map_err(|_| STATE_LOST.to_string())?;
    let document = Arc::make_mut(&mut *guard);
    let source = document.source();
    let start = byte_offset(source, edit.start).ok_or("Edit start is not a character boundary.")?;
    let end = byte_offset(source, edit.end).ok_or("Edit end is not a character boundary.")?;
    let shift = units(&edit.replacement) as i64 - (edit.end as i64 - edit.start as i64);
    let info = document
        .reparse_range(&ranga_core::TextEdit {
            start,
            end,
            replacement: edit.replacement,
        })
        .map_err(|error| error.to_string())?;
    Ok(snapshot(
        document,
        info.first,
        info.removed,
        info.inserted,
        shift,
    ))
}

#[frb(sync)]
pub fn document_outline(handle: &DocumentHandle) -> Result<Vec<OutlineEntry>, String> {
    let document = handle.current()?;
    let mut cursor = Cursor::new(document.source());
    Ok(document
        .outline()
        .into_iter()
        .map(|entry| OutlineEntry {
            title: entry.title,
            level: match entry.kind {
                OutlineKind::Scene => 0,
                OutlineKind::Section { level } => level,
            },
            offset: cursor.unit_at(document.elements()[entry.element].range.start),
        })
        .collect())
}

#[frb(sync)]
pub fn word_count(handle: &DocumentHandle) -> Result<u32, String> {
    Ok(handle.current()?.word_count())
}

pub async fn document_stats(
    handle: &DocumentHandle,
    settings: PageSettings,
) -> Result<DocumentStats, String> {
    let document = handle.current()?;
    let config = PageConfig::default();
    let pages = layout_pages(&document, &config);
    Ok(DocumentStats {
        words: document.word_count(),
        pages: pages.len() as u32,
        runtime_minutes: estimated_runtime_minutes(&pages, &config, settings.minutes_per_page),
    })
}

pub async fn paginate(handle: &DocumentHandle) -> Result<Vec<PageSnapshot>, String> {
    let document = handle.current()?;
    Ok(layout_pages(&document, &PageConfig::default())
        .into_iter()
        .map(|page| PageSnapshot {
            number: page.number,
            first_element: page.elements.start as u32,
            end_element: page.elements.end as u32,
            lines: page.lines.len() as u32,
        })
        .collect())
}

fn snapshot(
    document: &Document,
    first: usize,
    removed: usize,
    inserted: usize,
    shift: i64,
) -> DocumentSnapshot {
    let source = document.source();
    let mut cursor = Cursor::new(source);
    let title_page_end = document
        .title_page()
        .map(|page| cursor.unit_at(page.range.end));
    let mut cursor = Cursor::new(source);
    let elements = document.elements()[first..first + inserted]
        .iter()
        .map(|element| element_snapshot(source, element, &mut cursor))
        .collect();
    DocumentSnapshot {
        first: first as u32,
        removed: removed as u32,
        inserted: elements,
        shift,
        title_page_end,
        word_count: document.word_count(),
    }
}

fn element_snapshot(source: &str, element: &Element, cursor: &mut Cursor) -> ElementSnapshot {
    let start = cursor.unit_at(element.range.start);
    let end = cursor.unit_at(element.range.end);
    let at = |byte: usize| start + units(&source[element.range.start..byte]);
    ElementSnapshot {
        kind: element_type(&element.kind),
        start,
        end,
        spans: element
            .inlines
            .iter()
            .map(|inline| StyleSpan {
                style: match inline.kind {
                    InlineKind::Bold => SpanStyle::Bold,
                    InlineKind::Italic => SpanStyle::Italic,
                    InlineKind::Underline => SpanStyle::Underline,
                    InlineKind::Marker => SpanStyle::Marker,
                    InlineKind::Note => SpanStyle::Note,
                    InlineKind::Boneyard => SpanStyle::Boneyard,
                },
                start: at(inline.range.start),
                end: at(inline.range.end),
            })
            .collect(),
    }
}

fn element_type(kind: &ElementKind) -> ElementType {
    match kind {
        ElementKind::SceneHeading { .. } => ElementType::SceneHeading,
        ElementKind::Action => ElementType::Action,
        ElementKind::Character { .. } => ElementType::Character,
        ElementKind::Dialogue => ElementType::Dialogue,
        ElementKind::Parenthetical => ElementType::Parenthetical,
        ElementKind::Transition => ElementType::Transition,
        ElementKind::Centered => ElementType::Centered,
        ElementKind::PageBreak => ElementType::PageBreak,
        ElementKind::Section { .. } => ElementType::Section,
        ElementKind::Synopsis => ElementType::Synopsis,
        ElementKind::Note => ElementType::Note,
        ElementKind::Boneyard => ElementType::Boneyard,
        ElementKind::Lyric => ElementType::Lyric,
    }
}
