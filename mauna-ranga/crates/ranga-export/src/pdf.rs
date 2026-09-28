use std::fmt;

use printpdf::{
    FontId, Line, LinePoint, Op, ParsedFont, PdfDocument, PdfFontHandle, PdfPage, PdfSaveOptions,
    Point, Pt, TextItem,
};
use ranga_core::{Document, Run, TitleEntry, plain_text};
use ranga_layout::{Align, Column, Page, PageConfig};

const POINTS_PER_INCH: f32 = 72.0;
const UNDERLINE_OFFSET_PT: f32 = 1.5;
const UNDERLINE_THICKNESS_PT: f32 = 0.5;
const CENTERED_TITLE_KEYS: [&str; 5] = ["title", "credit", "author", "authors", "source"];
const CORNER_TITLE_KEYS: [&str; 2] = ["draft date", "contact"];

pub struct PdfFonts<'a> {
    pub regular: &'a [u8],
    pub bold: &'a [u8],
    pub italic: &'a [u8],
    pub bold_italic: &'a [u8],
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExportError {
    Font(&'static str),
}

impl fmt::Display for ExportError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ExportError::Font(style) => write!(f, "cannot read the {style} font file"),
        }
    }
}

impl std::error::Error for ExportError {}

struct FontSet {
    regular: FontId,
    bold: FontId,
    italic: FontId,
    bold_italic: FontId,
}

impl FontSet {
    fn for_run(&self, run: &Run) -> PdfFontHandle {
        let id = match (run.bold, run.italic) {
            (false, false) => &self.regular,
            (true, false) => &self.bold,
            (false, true) => &self.italic,
            (true, true) => &self.bold_italic,
        };
        PdfFontHandle::External(id.clone())
    }
}

struct Painter<'a> {
    config: &'a PageConfig,
    fonts: &'a FontSet,
    ops: Vec<Op>,
}

impl Painter<'_> {
    fn text_line(&mut self, row: u32, column: Column, align: Align, runs: &[Run]) {
        let config = self.config;
        let char_width = config.char_width_pt();
        let chars: usize = runs.iter().map(|run| run.text.chars().count()).sum();
        let width = chars as f32 * char_width;
        let left = column.left * POINTS_PER_INCH;
        let right = column.right * POINTS_PER_INCH;
        let x = match align {
            Align::Left => left,
            Align::Right => right - width,
            Align::Center => (left + right - width) / 2.0,
        };
        let y = (config.page_height - config.top_margin) * POINTS_PER_INCH
            - (row + 1) as f32 * config.line_height_pt();
        self.text_at(x, y, runs);
    }

    fn text_at(&mut self, x: f32, y: f32, runs: &[Run]) {
        let char_width = self.config.char_width_pt();
        self.ops.push(Op::StartTextSection);
        self.ops.push(Op::SetTextCursor {
            pos: Point { x: Pt(x), y: Pt(y) },
        });
        for run in runs {
            self.ops.push(Op::SetFont {
                font: self.fonts.for_run(run),
                size: Pt(self.config.font_size),
            });
            self.ops.push(Op::ShowText {
                items: vec![TextItem::Text(run.text.clone())],
            });
        }
        self.ops.push(Op::EndTextSection);

        let mut offset = 0;
        for run in runs {
            let count = run.text.chars().count();
            if run.underline {
                let start = x + offset as f32 * char_width;
                let end = start + count as f32 * char_width;
                let y = y - UNDERLINE_OFFSET_PT;
                self.ops.push(Op::SetOutlineThickness {
                    pt: Pt(UNDERLINE_THICKNESS_PT),
                });
                self.ops.push(Op::DrawLine {
                    line: Line {
                        points: vec![
                            LinePoint {
                                p: Point {
                                    x: Pt(start),
                                    y: Pt(y),
                                },
                                bezier: false,
                            },
                            LinePoint {
                                p: Point {
                                    x: Pt(end),
                                    y: Pt(y),
                                },
                                bezier: false,
                            },
                        ],
                        is_closed: false,
                    },
                });
            }
            offset += count;
        }
    }

    fn page_number(&mut self, number: u32) {
        let config = self.config;
        let runs = [Run {
            text: format!("{number}."),
            ..Run::default()
        }];
        let width = runs[0].text.chars().count() as f32 * config.char_width_pt();
        let x = config.action.right * POINTS_PER_INCH - width;
        let y = (config.page_height - config.page_number_top) * POINTS_PER_INCH
            - config.line_height_pt();
        self.text_at(x, y, &runs);
    }

    fn finish(&mut self) -> PdfPage {
        let config = self.config;
        PdfPage::new(
            Pt(config.page_width * POINTS_PER_INCH).into(),
            Pt(config.page_height * POINTS_PER_INCH).into(),
            std::mem::take(&mut self.ops),
        )
    }
}

pub fn export_pdf(
    doc: &Document,
    pages: &[Page],
    config: &PageConfig,
    fonts: &PdfFonts,
) -> Result<Vec<u8>, ExportError> {
    let title = doc
        .title_page()
        .and_then(|page| page.entry("title"))
        .map(|entry| entry_text(doc, entry))
        .unwrap_or_default();
    let mut pdf = PdfDocument::new(&title);
    let fonts = FontSet {
        regular: add_font(&mut pdf, fonts.regular, "regular")?,
        bold: add_font(&mut pdf, fonts.bold, "bold")?,
        italic: add_font(&mut pdf, fonts.italic, "italic")?,
        bold_italic: add_font(&mut pdf, fonts.bold_italic, "bold italic")?,
    };
    let mut painter = Painter {
        config,
        fonts: &fonts,
        ops: Vec::new(),
    };
    let mut output = Vec::new();

    if let Some(title_page) = doc.title_page() {
        let lines_per_page = config.lines_per_page();
        let block = |keys: &[&str]| -> Vec<Vec<Run>> {
            let mut lines: Vec<Vec<Run>> = Vec::new();
            for entry in &title_page.entries {
                if !keys.contains(&entry.key.to_lowercase().as_str()) {
                    continue;
                }
                if !lines.is_empty() {
                    lines.push(Vec::new());
                }
                lines.extend(entry.values.iter().map(|value| value.runs(doc.source())));
            }
            lines
        };
        let centered = block(&CENTERED_TITLE_KEYS);
        let first = lines_per_page.saturating_sub(centered.len() as u32) / 2;
        for (i, runs) in centered.iter().enumerate() {
            painter.text_line(first + i as u32, config.action, Align::Center, runs);
        }
        let corner = block(&CORNER_TITLE_KEYS);
        let first = lines_per_page.saturating_sub(corner.len() as u32);
        for (i, runs) in corner.iter().enumerate() {
            painter.text_line(first + i as u32, config.action, Align::Left, runs);
        }
        output.push(painter.finish());
    }

    for page in pages {
        if page.number > 1 {
            painter.page_number(page.number);
        }
        for line in &page.lines {
            painter.text_line(line.row, line.column, line.align, &line.runs);
        }
        output.push(painter.finish());
    }

    let bytes = pdf
        .with_pages(output)
        .save(&PdfSaveOptions::default(), &mut Vec::new());
    Ok(bytes)
}

fn add_font(
    pdf: &mut PdfDocument,
    bytes: &[u8],
    style: &'static str,
) -> Result<FontId, ExportError> {
    let font = ParsedFont::from_bytes(bytes, 0, &mut Vec::new()).ok_or(ExportError::Font(style))?;
    Ok(pdf.add_font(&font))
}

fn entry_text(doc: &Document, entry: &TitleEntry) -> String {
    entry
        .values
        .iter()
        .map(|value| plain_text(&value.runs(doc.source())))
        .collect::<Vec<_>>()
        .join(" ")
}
