use crate::document::{ByteRange, Inline, InlineKind};
use crate::lines::lines_in;

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Run {
    pub text: String,
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
}

impl Run {
    fn same_style(&self, bold: bool, italic: bool, underline: bool) -> bool {
        self.bold == bold && self.italic == italic && self.underline == underline
    }
}

pub fn visible_runs(source: &str, range: ByteRange, inlines: &[Inline]) -> Vec<Run> {
    let mut cuts = vec![range.start, range.end];
    for inline in inlines {
        cuts.push(inline.range.start.clamp(range.start, range.end));
        cuts.push(inline.range.end.clamp(range.start, range.end));
    }
    cuts.sort_unstable();
    cuts.dedup();

    let mut runs: Vec<Run> = Vec::new();
    for pair in cuts.windows(2) {
        let piece = ByteRange::new(pair[0], pair[1]);
        let covers = |kind: InlineKind| {
            inlines
                .iter()
                .any(|inline| inline.kind == kind && inline.range.contains(piece))
        };
        let hidden = inlines
            .iter()
            .any(|inline| inline.kind.is_hidden() && inline.range.contains(piece));
        if hidden {
            continue;
        }
        let bold = covers(InlineKind::Bold);
        let italic = covers(InlineKind::Italic);
        let underline = covers(InlineKind::Underline);
        let text = &source[piece.start..piece.end];
        match runs.last_mut() {
            Some(last) if last.same_style(bold, italic, underline) => last.text.push_str(text),
            _ => runs.push(Run {
                text: text.to_string(),
                bold,
                italic,
                underline,
            }),
        }
    }
    runs
}

pub fn plain_text(runs: &[Run]) -> String {
    runs.iter().map(|run| run.text.as_str()).collect()
}

pub(crate) fn count_words(text: &str) -> u32 {
    text.split_whitespace()
        .filter(|word| word.chars().any(char::is_alphanumeric))
        .count() as u32
}

pub(crate) fn parse_inlines(source: &str, range: ByteRange, markers: &[ByteRange]) -> Vec<Inline> {
    let mut inlines: Vec<Inline> = markers
        .iter()
        .map(|&range| Inline {
            kind: InlineKind::Marker,
            range,
        })
        .collect();
    find_notes(source, range, &mut inlines);
    let lines = lines_in(source, range.start, range.end);
    for &line in &lines {
        find_boneyards(source, line, &mut inlines);
    }
    let opaque: Vec<ByteRange> = inlines.iter().map(|inline| inline.range).collect();
    for &line in &lines {
        find_emphasis(source, line, &opaque, &mut inlines);
    }
    inlines
}

fn find_notes(source: &str, range: ByteRange, out: &mut Vec<Inline>) {
    let text = &source[range.start..range.end];
    let mut from = 0;
    while let Some(open) = text[from..].find("[[") {
        let open = from + open;
        let Some(close) = text[open + 2..].find("]]") else {
            break;
        };
        let end = open + 2 + close + 2;
        out.push(Inline {
            kind: InlineKind::Note,
            range: ByteRange::new(range.start + open, range.start + end),
        });
        from = end;
    }
}

fn find_boneyards(source: &str, line: ByteRange, out: &mut Vec<Inline>) {
    let text = &source[line.start..line.end];
    let mut from = 0;
    while let Some(open) = text[from..].find("/*") {
        let open = from + open;
        let Some(close) = text[open + 2..].find("*/") else {
            break;
        };
        let end = open + 2 + close + 2;
        out.push(Inline {
            kind: InlineKind::Boneyard,
            range: ByteRange::new(line.start + open, line.start + end),
        });
        from = end;
    }
}

#[derive(Clone, Copy)]
struct Delimiter {
    byte: u8,
    start: usize,
    len: usize,
}

fn emphasis_styles(byte: u8, len: usize) -> &'static [InlineKind] {
    match (byte, len) {
        (b'*', 1) => &[InlineKind::Italic],
        (b'*', 2) => &[InlineKind::Bold],
        (b'*', 3) => &[InlineKind::Bold, InlineKind::Italic],
        (b'_', 1) => &[InlineKind::Underline],
        _ => &[],
    }
}

fn find_emphasis(source: &str, line: ByteRange, opaque: &[ByteRange], out: &mut Vec<Inline>) {
    let bytes = source.as_bytes();
    let mut stack: Vec<Delimiter> = Vec::new();
    let mut i = line.start;
    while i < line.end {
        if let Some(skip) = opaque.iter().find(|r| r.start <= i && i < r.end) {
            i = skip.end;
            continue;
        }
        let byte = bytes[i];
        if byte == b'\\' && i + 1 < line.end && matches!(bytes[i + 1], b'*' | b'_') {
            out.push(Inline {
                kind: InlineKind::Marker,
                range: ByteRange::new(i, i + 1),
            });
            i += 2;
            continue;
        }
        if byte != b'*' && byte != b'_' {
            i += 1;
            continue;
        }
        let mut j = i;
        while j < line.end && bytes[j] == byte {
            j += 1;
        }
        let len = j - i;
        let styles = emphasis_styles(byte, len);
        let prev = source[line.start..i].chars().next_back();
        let next = source[j..line.end].chars().next();
        let can_open = next.is_some_and(|c| !c.is_whitespace());
        let can_close = prev.is_some_and(|c| !c.is_whitespace());
        let opener = if can_close && !styles.is_empty() {
            stack.iter().rposition(|d| d.byte == byte && d.len == len)
        } else {
            None
        };
        if let Some(position) = opener {
            let open = stack[position];
            stack.truncate(position);
            out.push(Inline {
                kind: InlineKind::Marker,
                range: ByteRange::new(open.start, open.start + len),
            });
            out.push(Inline {
                kind: InlineKind::Marker,
                range: ByteRange::new(i, j),
            });
            for &kind in styles {
                out.push(Inline {
                    kind,
                    range: ByteRange::new(open.start + len, i),
                });
            }
        } else if can_open && !styles.is_empty() {
            stack.push(Delimiter {
                byte,
                start: i,
                len,
            });
        }
        i = j;
    }
}
