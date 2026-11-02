use ranga_core::{Document, Run, plain_text};
use ranga_layout::{Align, Page, PageConfig};

const CENTERED_TITLE_KEYS: [&str; 5] = ["title", "credit", "author", "authors", "source"];
const PAGE_SEPARATOR: &str = "\n\x0c\n";

pub fn export_text(doc: &Document, pages: &[Page], config: &PageConfig) -> String {
    let mut sections: Vec<String> = Vec::new();
    if let Some(title_page) = doc.title_page() {
        let width = config.columns_in(config.action);
        let mut lines: Vec<String> = Vec::new();
        for entry in &title_page.entries {
            let centered = CENTERED_TITLE_KEYS.contains(&entry.key.to_lowercase().as_str());
            for value in &entry.values {
                let text = plain_text(&value.runs(doc.source()));
                if centered {
                    let pad = width.saturating_sub(text.chars().count()) / 2;
                    lines.push(format!("{}{text}", " ".repeat(pad)));
                } else {
                    lines.push(text);
                }
            }
            lines.push(String::new());
        }
        sections.push(lines.join("\n"));
    }
    for page in pages {
        sections.push(page_text(page, config));
    }
    let mut out = sections.join(PAGE_SEPARATOR);
    if !out.ends_with('\n') {
        out.push('\n');
    }
    out
}

fn page_text(page: &Page, config: &PageConfig) -> String {
    let mut rows: Vec<Vec<char>> = vec![Vec::new(); page.rows_used as usize];
    for line in &page.lines {
        let text = plain_text(&line.runs);
        let left = (line.column.left * config.chars_per_inch).round() as usize;
        let right = (line.column.right * config.chars_per_inch).round() as usize;
        let width = text.chars().count();
        let start = match line.align {
            Align::Left => left,
            Align::Right => right.saturating_sub(width),
            Align::Center => (left + right).saturating_sub(width) / 2,
        };
        put(&mut rows[line.row as usize], start, &line.runs);
    }
    let mut out = String::new();
    if page.number > 1 {
        let mut header = Vec::new();
        let number = [Run {
            text: format!("{}.", page.number),
            ..Run::default()
        }];
        let right = (config.action.right * config.chars_per_inch).round() as usize;
        put(
            &mut header,
            right.saturating_sub(number[0].text.chars().count()),
            &number,
        );
        out.push_str(&header.into_iter().collect::<String>());
        out.push_str("\n\n");
    }
    let lines: Vec<String> = rows
        .into_iter()
        .map(|row| row.into_iter().collect::<String>().trim_end().to_string())
        .collect();
    out.push_str(&lines.join("\n"));
    out
}

fn put(row: &mut Vec<char>, start: usize, runs: &[Run]) {
    let text = plain_text(runs);
    let end = start + text.chars().count();
    if row.len() < end {
        row.resize(end, ' ');
    }
    for (offset, c) in text.chars().enumerate() {
        row[start + offset] = c;
    }
}
