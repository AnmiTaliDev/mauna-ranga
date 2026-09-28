use crate::document::{Document, ElementKind};
use crate::inline::plain_text;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum OutlineKind {
    Section { level: u8 },
    Scene,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OutlineEntry {
    pub kind: OutlineKind,
    pub element: usize,
    pub title: String,
}

impl Document {
    pub fn outline(&self) -> Vec<OutlineEntry> {
        let mut entries = Vec::new();
        for (index, element) in self.elements.iter().enumerate() {
            let (kind, title) = match &element.kind {
                ElementKind::Section { level } => {
                    let title = self.text(element.range).trim_start_matches('#').trim();
                    (OutlineKind::Section { level: *level }, title.to_string())
                }
                ElementKind::SceneHeading { .. } => {
                    let title = plain_text(&element.runs(&self.source));
                    (OutlineKind::Scene, title.trim().to_string())
                }
                _ => continue,
            };
            entries.push(OutlineEntry {
                kind,
                element: index,
                title,
            });
        }
        entries
    }
}
