use crate::document::{
    ByteRange, Document, Element, ElementKind, Inline, InlineKind, TitleEntry, TitlePage,
    TitleValue,
};
use crate::inline::{count_words, parse_inlines, plain_text, visible_runs};
use crate::lines::{is_blank, line_at, line_start, lines_in, next_line_start};

const SCENE_PREFIXES: [&str; 6] = ["INT./EXT", "INT/EXT", "I/E", "INT", "EXT", "EST"];

pub fn parse_full(source: &str) -> Document {
    let (title_page, elements) = parse_region(source, 0, source.len());
    let word_count = title_page.as_ref().map_or(0, |page| page.words)
        + elements.iter().map(|e| e.words).sum::<u32>();
    Document {
        source: source.to_string(),
        title_page,
        elements,
        word_count,
    }
}

pub(crate) fn parse_region(
    source: &str,
    start: usize,
    end: usize,
) -> (Option<TitlePage>, Vec<Element>) {
    let lines = lines_in(source, start, end);
    let mut elements = Vec::new();
    let mut index = 0;
    let mut title_page = None;
    if start == 0 {
        let first_block = lines
            .iter()
            .position(|line| is_blank(text(source, *line)))
            .unwrap_or(lines.len());
        title_page = parse_title_page(source, &lines[..first_block]);
        if title_page.is_some() {
            index = first_block;
        }
    }

    let mut block: Vec<ByteRange> = Vec::new();
    while index < lines.len() {
        let line = lines[index];
        let body = text(source, line);
        if is_blank(body) {
            parse_block(source, &block, &mut elements);
            block.clear();
            index += 1;
            continue;
        }
        let open = line.start + (body.len() - body.trim_start().len());
        if body.trim_start().starts_with("/*")
            && let Some(close) = source[open + 2..].find("*/")
        {
            parse_block(source, &block, &mut elements);
            block.clear();
            let close = open + 2 + close + 2;
            let last = line_at(source, line_start(source, close));
            elements.push(Element {
                kind: ElementKind::Boneyard,
                range: ByteRange::new(line.start, last.end),
                inlines: Vec::new(),
                words: 0,
            });
            index = match next_line_start(source, last.start) {
                Some(next) if next <= end => lines.partition_point(|l| l.start < next),
                _ => lines.len(),
            };
            continue;
        }
        block.push(line);
        index += 1;
    }
    parse_block(source, &block, &mut elements);
    (title_page, elements)
}

fn text(source: &str, range: ByteRange) -> &str {
    &source[range.start..range.end]
}

fn parse_title_page(source: &str, lines: &[ByteRange]) -> Option<TitlePage> {
    let first = lines.first()?;
    title_key(text(source, *first))?;
    let mut entries: Vec<TitleEntry> = Vec::new();
    for &line in lines {
        let body = text(source, line);
        if let Some(colon) = title_key(body) {
            let value = trimmed(source, ByteRange::new(line.start + colon + 1, line.end));
            entries.push(TitleEntry {
                key: body[..colon].trim().to_string(),
                values: Vec::new(),
            });
            if !value.is_empty() {
                entries.last_mut()?.values.push(title_value(source, value));
            }
        } else if body.starts_with('\t') || body.starts_with("   ") {
            let value = trimmed(source, line);
            entries.last_mut()?.values.push(title_value(source, value));
        } else {
            return None;
        }
    }
    let words = entries
        .iter()
        .flat_map(|entry| &entry.values)
        .map(|value| count_words(&plain_text(&value.runs(source))))
        .sum();
    Some(TitlePage {
        range: ByteRange::new(first.start, lines.last()?.end),
        entries,
        words,
    })
}

fn title_key(line: &str) -> Option<usize> {
    let colon = line.find(':')?;
    let key = &line[..colon];
    let mut chars = key.chars();
    let valid = chars.next()?.is_alphabetic()
        && chars.all(|c| c.is_alphanumeric() || c == ' ' || c == '-' || c == '_');
    valid.then_some(colon)
}

fn title_value(source: &str, range: ByteRange) -> TitleValue {
    TitleValue {
        range,
        inlines: parse_inlines(source, range, &[]),
    }
}

fn trimmed(source: &str, range: ByteRange) -> ByteRange {
    let body = text(source, range);
    let start = range.start + (body.len() - body.trim_start().len());
    let end = range.end - (body.len() - body.trim_end().len());
    ByteRange::new(start, end.max(start))
}

#[derive(PartialEq)]
enum Flow {
    Normal,
    Dialogue,
}

struct Pending {
    kind: ElementKind,
    start: usize,
    end: usize,
    markers: Vec<ByteRange>,
}

struct BlockParser<'a> {
    source: &'a str,
    out: &'a mut Vec<Element>,
    pending: Option<Pending>,
}

impl BlockParser<'_> {
    fn flush(&mut self) {
        if let Some(pending) = self.pending.take() {
            push(
                self.source,
                self.out,
                pending.kind,
                ByteRange::new(pending.start, pending.end),
                pending.markers,
            );
        }
    }

    fn extend(&mut self, kind: ElementKind, line: ByteRange, markers: Vec<ByteRange>) {
        match &mut self.pending {
            Some(pending) if pending.kind == kind => {
                pending.end = line.end;
                pending.markers.extend(markers);
            }
            _ => {
                self.flush();
                self.pending = Some(Pending {
                    kind,
                    start: line.start,
                    end: line.end,
                    markers,
                });
            }
        }
    }

    fn single(&mut self, kind: ElementKind, range: ByteRange, markers: Vec<ByteRange>) {
        self.flush();
        push(self.source, self.out, kind, range, markers);
    }
}

fn parse_block(source: &str, lines: &[ByteRange], out: &mut Vec<Element>) {
    let mut parser = BlockParser {
        source,
        out,
        pending: None,
    };
    let mut flow = Flow::Normal;
    let count = lines.len();
    let mut i = 0;
    while i < count {
        let line = lines[i];
        let body = trimmed(source, line);
        let t = text(source, body);
        let marker = ByteRange::new(body.start, body.start + 1);

        if t.starts_with("[[")
            && !t.contains("]]")
            && let Some(close) =
                (i + 1..count).find(|&j| text(source, trimmed(source, lines[j])).ends_with("]]"))
        {
            let last = trimmed(source, lines[close]);
            parser.single(
                ElementKind::Note,
                ByteRange::new(body.start, last.end),
                Vec::new(),
            );
            i = close + 1;
            continue;
        }
        if is_note(t) {
            parser.single(ElementKind::Note, body, Vec::new());
            i += 1;
            continue;
        }

        if flow == Flow::Dialogue {
            if t.starts_with('(') && t.ends_with(')') {
                parser.single(ElementKind::Parenthetical, body, Vec::new());
            } else if t.starts_with('~') {
                parser.extend(ElementKind::Lyric, body, vec![marker]);
            } else {
                parser.extend(ElementKind::Dialogue, body, Vec::new());
            }
            i += 1;
            continue;
        }

        let alone = count == 1;
        if t.starts_with('!') {
            parser.extend(ElementKind::Action, line, vec![marker]);
        } else if is_page_break(t) {
            parser.single(ElementKind::PageBreak, body, Vec::new());
        } else if t.starts_with('=') {
            parser.single(ElementKind::Synopsis, body, vec![marker]);
        } else if t.starts_with('#') {
            let level = t.bytes().take_while(|&b| b == b'#').count();
            let hashes = ByteRange::new(body.start, body.start + level);
            let level = level.min(u8::MAX as usize) as u8;
            parser.single(ElementKind::Section { level }, body, vec![hashes]);
        } else if t.starts_with('~') {
            parser.extend(ElementKind::Lyric, body, vec![marker]);
        } else if t.len() >= 2 && t.starts_with('>') && t.ends_with('<') {
            let close = ByteRange::new(body.end - 1, body.end);
            parser.extend(ElementKind::Centered, body, vec![marker, close]);
        } else if t.starts_with('>') {
            parser.single(ElementKind::Transition, body, vec![marker]);
        } else if is_forced_scene(t) {
            let (number, number_marker) = scene_number(source, body);
            let mut markers = vec![marker];
            markers.extend(number_marker);
            parser.single(ElementKind::SceneHeading { number }, body, markers);
        } else if t.starts_with('@') {
            let (extension, dual, mut markers) = character_parts(source, body);
            markers.push(marker);
            parser.single(ElementKind::Character { extension, dual }, body, markers);
            flow = Flow::Dialogue;
        } else if alone && is_scene_heading(t) {
            let (number, number_marker) = scene_number(source, body);
            parser.single(
                ElementKind::SceneHeading { number },
                body,
                number_marker.into_iter().collect(),
            );
        } else if alone && is_transition(text(source, line)) {
            parser.single(ElementKind::Transition, body, Vec::new());
        } else if i == 0 && count > 1 && is_character(t) {
            let (extension, dual, markers) = character_parts(source, body);
            parser.single(ElementKind::Character { extension, dual }, body, markers);
            flow = Flow::Dialogue;
        } else {
            parser.extend(ElementKind::Action, line, Vec::new());
        }
        i += 1;
    }
    parser.flush();
}

fn push(
    source: &str,
    out: &mut Vec<Element>,
    kind: ElementKind,
    range: ByteRange,
    markers: Vec<ByteRange>,
) {
    let inlines = if kind.is_printed() {
        parse_inlines(source, range, &markers)
    } else {
        markers
            .into_iter()
            .map(|range| Inline {
                kind: InlineKind::Marker,
                range,
            })
            .collect()
    };
    let words = if kind.is_printed() {
        count_words(&plain_text(&visible_runs(source, range, &inlines)))
    } else {
        0
    };
    out.push(Element {
        kind,
        range,
        inlines,
        words,
    });
}

fn is_note(t: &str) -> bool {
    t.starts_with("[[") && t.ends_with("]]") && t[2..].find("]]") == Some(t.len() - 4)
}

fn is_page_break(t: &str) -> bool {
    t.len() >= 3 && t.bytes().all(|b| b == b'=')
}

fn is_forced_scene(t: &str) -> bool {
    let mut chars = t.chars();
    chars.next() == Some('.') && chars.next().is_some_and(char::is_alphanumeric)
}

fn is_scene_heading(t: &str) -> bool {
    let upper = t.to_ascii_uppercase();
    SCENE_PREFIXES.iter().any(|prefix| {
        upper.starts_with(prefix)
            && matches!(upper.as_bytes().get(prefix.len()), Some(b'.') | Some(b' '))
    })
}

fn is_transition(line: &str) -> bool {
    let t = line.trim_start();
    t.ends_with("TO:") && !t.chars().any(char::is_lowercase)
}

fn is_character(t: &str) -> bool {
    let name = t.trim_end_matches('^').trim_end();
    let name = name.split('(').next().unwrap_or(name);
    name.chars().any(char::is_alphabetic) && !name.chars().any(char::is_lowercase)
}

fn character_parts(source: &str, body: ByteRange) -> (Option<String>, bool, Vec<ByteRange>) {
    let t = text(source, body);
    let mut markers = Vec::new();
    let without_caret = t.trim_end_matches('^');
    let dual = without_caret.len() < t.len();
    if dual {
        markers.push(ByteRange::new(body.start + without_caret.len(), body.end));
    }
    let extension = without_caret
        .find('(')
        .map(|open| without_caret[open..].trim_end().to_string());
    (extension, dual, markers)
}

fn scene_number(source: &str, body: ByteRange) -> (Option<String>, Option<ByteRange>) {
    let t = text(source, body);
    if !t.ends_with('#') || t.len() < 3 {
        return (None, None);
    }
    let Some(open) = t[..t.len() - 1].rfind('#') else {
        return (None, None);
    };
    let number = &t[open + 1..t.len() - 1];
    let valid = !number.is_empty()
        && number
            .chars()
            .all(|c| c.is_alphanumeric() || c == '-' || c == '.');
    if !valid {
        return (None, None);
    }
    (
        Some(number.to_string()),
        Some(ByteRange::new(body.start + open, body.end)),
    )
}
