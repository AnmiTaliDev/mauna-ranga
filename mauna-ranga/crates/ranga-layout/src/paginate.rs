use std::ops::Range;

use ranga_core::{Document, Element, ElementKind, Run};

use crate::config::{Column, PageConfig};
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
}

struct Block {
    kind: BlockKind,
    space: u32,
    lines: Vec<Line>,
    page_break_before: bool,
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
    let mut blocks: Vec<Block> = Vec::new();
    let mut in_dialogue = false;
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
            let column = if *kind == ElementKind::Parenthetical {
                config.parenthetical
            } else {
                config.dialogue
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
        let block = match kind {
            ElementKind::Character { extension, .. } => {
                let lines = lay_out(
                    source,
                    element,
                    index,
                    config.character,
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
            },
        };
        blocks.push(Block {
            page_break_before: std::mem::take(&mut page_break),
            ..block
        });
    }
    blocks
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
        self.lines.push(PageLine {
            row: self.row,
            column: line.column,
            align: line.align,
            runs: line.runs.clone(),
            element: line.element,
        });
        self.row += 1;
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
                available
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
                available - reserved
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
