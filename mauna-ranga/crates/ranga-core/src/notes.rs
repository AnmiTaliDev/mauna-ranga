use crate::document::{Document, ElementKind, InlineKind};
use crate::inline::plain_text;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NoteEntry {
    pub text: String,
    pub start: usize,
    pub scene: Option<String>,
}

impl Document {
    pub fn notes(&self) -> Vec<NoteEntry> {
        let mut notes: Vec<NoteEntry> = Vec::new();
        let mut scene: Option<String> = None;
        for element in &self.elements {
            if matches!(element.kind, ElementKind::SceneHeading { .. }) {
                scene = Some(plain_text(&element.runs(&self.source)).trim().to_string());
            }
            if element.kind == ElementKind::Note {
                notes.push(self.note_entry(element.range.start, element.range.end, &scene));
                continue;
            }
            for inline in &element.inlines {
                if inline.kind == InlineKind::Note {
                    notes.push(self.note_entry(inline.range.start, inline.range.end, &scene));
                }
            }
        }
        notes.sort_by_key(|note| note.start);
        notes
    }

    fn note_entry(&self, start: usize, end: usize, scene: &Option<String>) -> NoteEntry {
        let raw = &self.source[start..end];
        let inner = raw.strip_prefix("[[").unwrap_or(raw);
        let inner = inner.strip_suffix("]]").unwrap_or(inner);
        NoteEntry {
            text: inner.split_whitespace().collect::<Vec<_>>().join(" "),
            start,
            scene: scene.clone(),
        }
    }
}
