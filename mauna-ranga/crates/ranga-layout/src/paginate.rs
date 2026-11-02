use std::ops::Range;

use ranga_core::{Document, Element, ElementKind, Run, plain_text};

use crate::config::{Column, DualColumns, PageConfig};
use crate::wrap::{WrapOptions, wrap};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Align {
    Left,
    Center,
    Right,
}

#[derive(Debug, Clone, PartialEq)]
pub struct PageLine {
    pub row: u32,
    pub column: Column,
    pub align: Align,
    pub runs: Vec<Run>,
    pub element: Option<usize>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Page {
    pub number: u32,
    pub elements: Range<usize>,
    pub lines: Vec<PageLine>,
    pub rows_used: u32,
}

struct Line {
    column: Column,
    align: Align,
    runs: Vec<Run>,
    element: Option<usize>,
}

enum BlockKind {
    Fixed,
    Split,
    Heading,
    Dialogue { header: usize, continued: Vec<Run> },
    Dual { right: Vec<Line> },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Side {
    Left,
    Right,
}

struct Block {
    kind: BlockKind,
    space: u32,
    lines: Vec<Line>,
    page_break_before: bool,
    dual: Option<Side>,
}

pub fn paginate(doc: &Document, config: &PageConfig) -> Vec<Page> {
    let blocks = build_blocks(doc, config);
    let mut pager = Pager {
        capacity: config.lines_per_page(),
        pages: Vec::new(),
        lines: Vec::new(),
        row: 0,
    };
    for (index, block) in blocks.iter().enumerate() {
        let keep = match (&block.kind, blocks.get(index + 1)) {
            (BlockKind::Heading, Some(next)) if !next.page_break_before => {
                next.space + next.lines.len().min(2) as u32
            }
            _ => 0,
        };
        pager.place_block(block, keep, config);
    }
    pager.finish_page();
    pager.pages
}

fn build_blocks(doc: &Document, config: &PageConfig) -> Vec<Block> {
    let source = doc.source();
    let sides = dual_sides(doc);
    let mut blocks: Vec<Block> = Vec::new();
    let mut in_dialogue = false;
    let mut side = None;
    let mut page_break = false;
    for (index, element) in doc.elements().iter().enumerate() {
        let kind = &element.kind;
        if *kind == ElementKind::PageBreak {
            page_break = true;
            in_dialogue = false;
            continue;
        }
        if !kind.is_printed() {
            continue;
        }
        let dialogue_part = matches!(
            kind,
            ElementKind::Parenthetical | ElementKind::Dialogue | ElementKind::Lyric
        );
        if in_dialogue
            && dialogue_part
            && let Some(block) = blocks.last_mut()
        {
            let column = match (side, *kind == ElementKind::Parenthetical) {
                (Some(side), true) => dual_columns(side, config).parenthetical,
                (Some(side), false) => dual_columns(side, config).dialogue,
                (None, true) => config.parenthetical,
                (None, false) => config.dialogue,
            };
            block.lines.extend(lay_out(
                source,
                element,
                index,
                column,
                Align::Left,
                false,
                config,
            ));
            continue;
        }
        in_dialogue = matches!(kind, ElementKind::Character { .. });
        side = sides[index];
        let block = match kind {
            ElementKind::Character { extension, .. } => {
                let character = side.map_or(config.character, |side| {
                    dual_columns(side, config).character
                });
                let lines = lay_out(
                    source,
                    element,
                    index,
                    character,
                    Align::Left,
                    false,
                    config,
                );
                let continued = continued_header(&lines, extension.as_deref(), config);
                Block {
                    kind: BlockKind::Dialogue {
                        header: lines.len(),
                        continued,
                    },
                    space: config.element_space,
                    lines,
                    page_break_before: false,
                    dual: side,
                }
            }
            ElementKind::SceneHeading { .. } => Block {
                kind: BlockKind::Heading,
                space: config.scene_heading_space,
                lines: lay_out(
                    source,
                    element,
                    index,
                    config.action,
                    Align::Left,
                    true,
                    config,
                ),
                page_break_before: false,
                dual: None,
            },
            ElementKind::Transition => Block {
                kind: BlockKind::Fixed,
                space: config.element_space,
                lines: lay_out(
                    source,
                    element,
                    index,
                    config.transition,
                    Align::Right,
                    true,
                    config,
                ),
                page_break_before: false,
                dual: None,
            },
            ElementKind::Centered => Block {
                kind: BlockKind::Split,
                space: config.element_space,
                lines: lay_out(
                    source,
                    element,
                    index,
                    config.action,
                    Align::Center,
                    false,
                    config,
                ),
                page_break_before: false,
                dual: None,
            },
            ElementKind::Parenthetical => Block {
                kind: BlockKind::Split,
                space: config.element_space,
                lines: lay_out(
                    source,
                    element,
                    index,
                    config.parenthetical,
                    Align::Left,
                    false,
                    config,
                ),
                page_break_before: false,
                dual: None,
            },
            ElementKind::Dialogue => Block {
                kind: BlockKind::Split,
                space: config.element_space,
                lines: lay_out(
                    source,
                    element,
                    index,
                    config.dialogue,
                    Align::Left,
                    false,
                    config,
                ),
                page_break_before: false,
                dual: None,
            },
            _ => Block {
                kind: BlockKind::Split,
                space: config.element_space,
                lines: lay_out(
                    source,
                    element,
                    index,
                    config.action,
                    Align::Left,
                    false,
                    config,
                ),
                page_break_before: false,
                dual: None,
            },
        };
        blocks.push(Block {
            page_break_before: std::mem::take(&mut page_break),
            ..block
        });
    }
    join_dual(blocks)
}

fn join_dual(blocks: Vec<Block>) -> Vec<Block> {
    let mut joined: Vec<Block> = Vec::new();
    for block in blocks {
        if block.dual == Some(Side::Right) {
            let left = joined.pop().expect("left half precedes right half");
            joined.push(Block {
                kind: BlockKind::Dual { right: block.lines },
                space: left.space,
                lines: left.lines,
                page_break_before: left.page_break_before,
                dual: None,
            });
        } else {
            joined.push(block);
        }
    }
    joined
}

fn dual_sides(doc: &Document) -> Vec<Option<Side>> {
    let elements = doc.elements();
    let mut sides: Vec<Option<Side>> = vec![None; elements.len()];
    let mut last_character: Option<usize> = None;
    let mut only_dialogue_since = false;
    for (index, element) in elements.iter().enumerate() {
        match &element.kind {
            ElementKind::Character { dual, .. } => {
                if *dual
                    && only_dialogue_since
                    && let Some(left) = last_character
                    && sides[left].is_none()
                {
                    sides[left] = Some(Side::Left);
                    sides[index] = Some(Side::Right);
                }
                last_character = Some(index);
                only_dialogue_since = true;
            }
            ElementKind::Parenthetical | ElementKind::Dialogue | ElementKind::Lyric => {}
            kind if !kind.is_printed() => {}
            _ => only_dialogue_since = false,
        }
    }
    sides
}

fn dual_columns(side: Side, config: &PageConfig) -> DualColumns {
    match side {
        Side::Left => config.dual_left,
        Side::Right => config.dual_right,
    }
}

fn lay_out(
    source: &str,
    element: &Element,
    index: usize,
    column: Column,
    align: Align,
    uppercase: bool,
    config: &PageConfig,
) -> Vec<Line> {
    let options = WrapOptions {
        width: config.columns_in(column),
        keep_indent: element.kind == ElementKind::Action,
        uppercase,
    };
    wrap(&element.runs(source), &options)
        .into_iter()
        .map(|runs| Line {
            column,
            align,
            runs,
            element: Some(index),
        })
        .collect()
}

fn ends_sentence(line: &Line) -> bool {
    plain_text(&line.runs)
        .trim_end()
        .trim_end_matches(['"', '\'', ')', '\u{201d}', '\u{2019}'])
        .ends_with(['.', '!', '?', '\u{2026}'])
}

fn sentence_break(lines: &[Line], max_take: usize) -> usize {
    (2..=max_take)
        .rev()
        .find(|&take| ends_sentence(&lines[take - 1]))
        .unwrap_or(max_take)
}

fn continued_header(lines: &[Line], extension: Option<&str>, config: &PageConfig) -> Vec<Run> {
    let mut runs = lines
        .first()
        .map(|line| line.runs.clone())
        .unwrap_or_default();
    let already = extension.is_some_and(|ext| {
        ext.to_uppercase().contains(
            config
                .continued_label
                .trim_matches(|c| c == '(' || c == ')'),
        )
    });
    if !already {
        runs.push(Run {
            text: format!(" {}", config.continued_label),
            ..Run::default()
        });
    }
    runs
}

struct Pager {
    capacity: u32,
    pages: Vec<Page>,
    lines: Vec<PageLine>,
    row: u32,
}

impl Pager {
    fn is_empty(&self) -> bool {
        self.lines.is_empty()
    }

    fn remaining(&self) -> u32 {
        self.capacity.saturating_sub(self.row)
    }

    fn skip(&mut self, rows: u32) {
        if !self.is_empty() {
            self.row += rows;
        }
    }

    fn place(&mut self, line: &Line) {
        if self.row >= self.capacity && !self.is_empty() {
            self.finish_page();
        }
        self.push(line);
        self.row += 1;
    }

    fn push(&mut self, line: &Line) {
        self.lines.push(PageLine {
            row: self.row,
            column: line.column,
            align: line.align,
            runs: line.runs.clone(),
            element: line.element,
        });
    }

    fn place_dual(&mut self, block: &Block, right: &[Line]) {
        let height = block.lines.len().max(right.len());
        if self.space_for(block) + height as u32 > self.remaining() {
            self.finish_page();
        }
        self.skip(block.space);
        for index in 0..height {
            if self.row >= self.capacity && !self.is_empty() {
                self.finish_page();
            }
            for line in block.lines.get(index).into_iter().chain(right.get(index)) {
                self.push(line);
            }
            self.row += 1;
        }
    }

    fn finish_page(&mut self) {
        if self.is_empty() {
            return;
        }
        let lines = std::mem::take(&mut self.lines);
        let indices = lines.iter().filter_map(|line| line.element);
        let first = indices.clone().min().unwrap_or(0);
        let last = indices.max().map_or(first, |i| i + 1);
        self.pages.push(Page {
            number: self.pages.len() as u32 + 1,
            elements: first..last,
            lines,
            rows_used: self.row,
        });
        self.row = 0;
    }

    fn space_for(&self, block: &Block) -> u32 {
        if self.is_empty() { 0 } else { block.space }
    }

    fn place_block(&mut self, block: &Block, keep: u32, config: &PageConfig) {
        if block.page_break_before {
            self.finish_page();
        }
        match &block.kind {
            BlockKind::Fixed | BlockKind::Heading => {
                let need = self.space_for(block) + block.lines.len() as u32 + keep;
                if need > self.remaining() {
                    self.finish_page();
                }
                self.skip(block.space);
                for line in &block.lines {
                    self.place(line);
                }
            }
            BlockKind::Split => self.place_split(block),
            BlockKind::Dual { right } => self.place_dual(block, right),
            BlockKind::Dialogue { header, continued } => {
                self.place_dialogue(block, *header, continued, config)
            }
        }
    }

    fn place_split(&mut self, block: &Block) {
        let lines = &block.lines;
        let mut next = 0;
        let mut first = true;
        while next < lines.len() {
            let space = if first { self.space_for(block) } else { 0 };
            let available = self.remaining().saturating_sub(space) as usize;
            let left = lines.len() - next;
            let take = if left <= available {
                left
            } else if available >= 2 && left - available >= 2 {
                sentence_break(&lines[next..], available)
            } else if !self.is_empty() {
                self.finish_page();
                continue;
            } else {
                available.max(1)
            };
            self.skip(space);
            for line in &lines[next..next + take] {
                self.place(line);
            }
            next += take;
            first = false;
            if next < lines.len() {
                self.finish_page();
            }
        }
    }

    fn place_dialogue(
        &mut self,
        block: &Block,
        header: usize,
        continued: &[Run],
        config: &PageConfig,
    ) {
        let content = &block.lines[header..];
        let character = block
            .lines
            .first()
            .map_or(config.character, |line| line.column);
        let continued_line = Line {
            column: character,
            align: Align::Left,
            runs: continued.to_vec(),
            element: block.lines.first().and_then(|line| line.element),
        };
        let more_line = Line {
            column: character,
            align: Align::Left,
            runs: vec![Run {
                text: config.more_label.clone(),
                ..Run::default()
            }],
            element: None,
        };
        let mut heading: Vec<&Line> = block.lines[..header].iter().collect();
        let mut next = 0;
        let mut first = true;
        loop {
            let space = if first { self.space_for(block) } else { 0 };
            let available = self.remaining().saturating_sub(space) as usize;
            let left = content.len() - next;
            let reserved = heading.len() + 1;
            let take = if heading.len() + left <= available {
                left
            } else if available >= reserved + 2 {
                sentence_break(&content[next..], available - reserved)
            } else if !self.is_empty() {
                self.finish_page();
                continue;
            } else {
                available.saturating_sub(reserved).max(1).min(left)
            };
            self.skip(space);
            for line in &heading {
                self.place(line);
            }
            for line in &content[next..next + take] {
                self.place(line);
            }
            next += take;
            if next >= content.len() {
                break;
            }
            self.place(&more_line);
            self.finish_page();
            heading = vec![&continued_line];
            first = false;
        }
    }
}
