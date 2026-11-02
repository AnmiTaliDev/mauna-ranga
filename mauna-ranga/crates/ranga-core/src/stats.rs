use std::collections::HashMap;

use crate::document::{Document, ElementKind};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CharacterStat {
    pub name: String,
    pub speeches: u32,
    pub words: u32,
}

impl Document {
    pub fn character_stats(&self) -> Vec<CharacterStat> {
        let mut stats: Vec<CharacterStat> = Vec::new();
        let mut index_of: HashMap<String, usize> = HashMap::new();
        let mut current: Option<usize> = None;
        for element in &self.elements {
            match &element.kind {
                ElementKind::Character { .. } => {
                    let name = character_name(self.text(element.range));
                    current = if name.is_empty() {
                        None
                    } else {
                        let index = *index_of.entry(name.clone()).or_insert_with(|| {
                            stats.push(CharacterStat {
                                name,
                                speeches: 0,
                                words: 0,
                            });
                            stats.len() - 1
                        });
                        stats[index].speeches += 1;
                        Some(index)
                    };
                }
                ElementKind::Dialogue | ElementKind::Lyric => {
                    if let Some(index) = current {
                        stats[index].words += element.words;
                    }
                }
                ElementKind::Parenthetical => {}
                kind if !kind.is_printed() => {}
                _ => current = None,
            }
        }
        stats.sort_by(|a, b| b.words.cmp(&a.words).then_with(|| a.name.cmp(&b.name)));
        stats
    }
}

fn character_name(line: &str) -> String {
    let line = line.trim();
    let line = line.strip_prefix('@').unwrap_or(line);
    let end = line.find(['(', '^']).unwrap_or(line.len());
    line[..end].trim().to_uppercase()
}
