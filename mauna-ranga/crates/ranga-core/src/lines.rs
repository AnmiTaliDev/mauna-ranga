use crate::document::ByteRange;

pub(crate) fn line_start(source: &str, pos: usize) -> usize {
    source[..pos].rfind('\n').map_or(0, |i| i + 1)
}

pub(crate) fn line_end(source: &str, pos: usize) -> usize {
    source[pos..].find('\n').map_or(source.len(), |i| pos + i)
}

pub(crate) fn content(source: &str, start: usize, end: usize) -> ByteRange {
    if end > start && source.as_bytes()[end - 1] == b'\r' {
        ByteRange::new(start, end - 1)
    } else {
        ByteRange::new(start, end)
    }
}

pub(crate) fn is_blank(line: &str) -> bool {
    line.trim().is_empty() && line != "  "
}

pub(crate) fn lines_in(source: &str, start: usize, end: usize) -> Vec<ByteRange> {
    let mut lines = Vec::new();
    let mut pos = start;
    loop {
        let stop = line_end(source, pos).min(end);
        lines.push(content(source, pos, stop));
        if stop >= end {
            break;
        }
        pos = stop + 1;
    }
    lines
}

pub(crate) fn line_at(source: &str, start: usize) -> ByteRange {
    content(source, start, line_end(source, start))
}

pub(crate) fn previous_line_start(source: &str, start: usize) -> Option<usize> {
    if start == 0 {
        None
    } else {
        Some(line_start(source, start - 1))
    }
}

pub(crate) fn next_line_start(source: &str, start: usize) -> Option<usize> {
    let end = line_end(source, start);
    if end >= source.len() {
        None
    } else {
        Some(end + 1)
    }
}
