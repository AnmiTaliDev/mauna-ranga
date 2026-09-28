use std::fmt;

use crate::document::{Document, ElementKind};
use crate::lines::{is_blank, line_at, line_end, line_start, next_line_start, previous_line_start};
use crate::parser::{parse_full, parse_region};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextEdit {
    pub start: usize,
    pub end: usize,
    pub replacement: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EditError {
    InvertedRange,
    OutOfBounds,
    NotCharBoundary,
}

impl fmt::Display for EditError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let message = match self {
            EditError::InvertedRange => "edit start is after edit end",
            EditError::OutOfBounds => "edit range is outside the document",
            EditError::NotCharBoundary => "edit range splits a UTF-8 character",
        };
        f.write_str(message)
    }
}

impl std::error::Error for EditError {}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ReparseInfo {
    pub first: usize,
    pub removed: usize,
    pub inserted: usize,
    pub byte_delta: isize,
    pub full: bool,
}

impl Document {
    pub fn reparse_range(&mut self, edit: &TextEdit) -> Result<ReparseInfo, EditError> {
        validate(&self.source, edit)?;
        let delta = edit.replacement.len() as isize - (edit.end - edit.start) as isize;
        let window_start = window_start(&self.source, edit.start);
        let window_end = window_end(&self.source, edit.end);

        let first = self
            .elements
            .partition_point(|e| e.range.start < window_start);
        let last = self
            .elements
            .partition_point(|e| e.range.start < window_end);
        let touches_boneyard = self.elements
            [first.saturating_sub(1)..(last + 1).min(self.elements.len())]
            .iter()
            .any(|e| e.kind == ElementKind::Boneyard);

        let old_window = &self.source[window_start..window_end];
        let has_delimiter = |text: &str| text.contains("/*") || text.contains("*/");
        let mut source = String::with_capacity(self.source.len() + edit.replacement.len());
        source.push_str(&self.source[..edit.start]);
        source.push_str(&edit.replacement);
        source.push_str(&self.source[edit.end..]);
        let new_end = window_end
            .checked_add_signed(delta)
            .expect("window end stays in bounds");
        let new_window = &source[window_start..new_end];

        if touches_boneyard || has_delimiter(old_window) || has_delimiter(new_window) {
            let removed = self.elements.len();
            *self = parse_full(&source);
            return Ok(ReparseInfo {
                first: 0,
                removed,
                inserted: self.elements.len(),
                byte_delta: delta,
                full: true,
            });
        }

        let (title_page, fresh) = parse_region(&source, window_start, new_end);
        let removed_words: u32 = self.elements[first..last].iter().map(|e| e.words).sum();
        let inserted_words: u32 = fresh.iter().map(|e| e.words).sum();
        let inserted = fresh.len();
        if window_start == 0 {
            let old_title = self.title_page.as_ref().map_or(0, |page| page.words);
            let new_title = title_page.as_ref().map_or(0, |page| page.words);
            self.word_count = self.word_count - old_title + new_title;
            self.title_page = title_page;
        }
        self.word_count = self.word_count - removed_words + inserted_words;
        self.elements.splice(first..last, fresh);
        for element in &mut self.elements[first + inserted..] {
            element.shift(delta);
        }
        self.source = source;
        Ok(ReparseInfo {
            first,
            removed: last - first,
            inserted,
            byte_delta: delta,
            full: false,
        })
    }
}

fn validate(source: &str, edit: &TextEdit) -> Result<(), EditError> {
    if edit.start > edit.end {
        return Err(EditError::InvertedRange);
    }
    if edit.end > source.len() {
        return Err(EditError::OutOfBounds);
    }
    if !source.is_char_boundary(edit.start) || !source.is_char_boundary(edit.end) {
        return Err(EditError::NotCharBoundary);
    }
    Ok(())
}

fn blank_at(source: &str, start: usize) -> bool {
    let line = line_at(source, start);
    is_blank(&source[line.start..line.end])
}

fn block_start(source: &str, mut start: usize) -> usize {
    while let Some(previous) = previous_line_start(source, start) {
        if blank_at(source, previous) {
            break;
        }
        start = previous;
    }
    start
}

fn block_end(source: &str, mut start: usize) -> usize {
    while let Some(next) = next_line_start(source, start) {
        if blank_at(source, next) {
            break;
        }
        start = next;
    }
    line_end(source, start)
}

fn window_start(source: &str, pos: usize) -> usize {
    let mut start = block_start(source, line_start(source, pos));
    while let Some(previous) = previous_line_start(source, start) {
        start = previous;
        if !blank_at(source, previous) {
            break;
        }
    }
    block_start(source, start)
}

fn window_end(source: &str, pos: usize) -> usize {
    let mut start = line_start(source, pos);
    let end = block_end(source, start);
    start = line_start(source, end);
    while let Some(next) = next_line_start(source, start) {
        start = next;
        if !blank_at(source, next) {
            break;
        }
    }
    block_end(source, start)
}
