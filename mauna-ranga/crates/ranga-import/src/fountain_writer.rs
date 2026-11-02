use crate::fdx_reader::{Paragraph, Run, Script};

const SCENE_PREFIXES: [&str; 6] = ["INT./EXT", "INT/EXT", "INT", "EXT", "EST", "I/E"];

pub(crate) fn write_fountain(script: &Script) -> String {
    let mut blocks: Vec<String> = Vec::new();
    if let Some(title) = title_block(&script.title_page) {
        blocks.push(title);
    }
    let mut in_dialogue = false;
    for paragraph in &script.body {
        let text = runs_text(&paragraph.runs);
        if paragraph.new_page {
            blocks.push("===".to_string());
            in_dialogue = false;
        }
        if text.trim().is_empty() {
            continue;
        }
        match paragraph.kind.as_str() {
            "Character" => {
                blocks.push(character_line(&text, paragraph.second_dual));
                in_dialogue = true;
            }
            "Parenthetical" if in_dialogue => {
                append_line(&mut blocks, &parenthetical_line(&text));
            }
            "Dialogue" if in_dialogue => {
                append_line(&mut blocks, &dialogue_lines(&text));
            }
            kind => {
                in_dialogue = false;
                blocks.push(match kind {
                    "Scene Heading" => heading_line(&text, paragraph.number.as_deref()),
                    "Transition" => transition_line(&text),
                    _ if paragraph.centered => centered_lines(&text),
                    _ => action_lines(&text),
                });
            }
        }
    }
    let mut out = blocks.join("\n\n");
    out.push('\n');
    out
}

fn append_line(blocks: &mut [String], line: &str) {
    if let Some(block) = blocks.last_mut() {
        block.push('\n');
        block.push_str(line);
    }
}

fn title_block(paragraphs: &[Paragraph]) -> Option<String> {
    let mut centered: Vec<String> = Vec::new();
    let mut corner: Vec<String> = Vec::new();
    for paragraph in paragraphs {
        let text = runs_text(&paragraph.runs);
        if text.trim().is_empty() {
            continue;
        }
        if paragraph.centered {
            centered.push(text);
        } else {
            corner.push(text);
        }
    }
    let mut lines: Vec<String> = Vec::new();
    if let Some((title, authors)) = centered.split_first() {
        lines.push(format!("Title: {title}"));
        if let Some((first, rest)) = authors.split_first() {
            lines.push(format!("Author: {first}"));
            lines.extend(rest.iter().map(|line| format!("   {line}")));
        }
    }
    if let Some((first, rest)) = corner.split_first() {
        lines.push(format!("Contact: {first}"));
        lines.extend(rest.iter().map(|line| format!("   {line}")));
    }
    (!lines.is_empty()).then(|| lines.join("\n"))
}

fn heading_line(text: &str, number: Option<&str>) -> String {
    let mut line = if is_scene_heading(text) {
        text.trim().to_string()
    } else {
        format!(".{}", text.trim())
    };
    if let Some(number) = number {
        line.push_str(&format!(" #{number}#"));
    }
    line
}

fn character_line(text: &str, dual: bool) -> String {
    let name = text.trim();
    let base = name.split('(').next().unwrap_or(name);
    let mut line = if base.chars().any(char::is_lowercase) || !base.chars().any(char::is_alphabetic)
    {
        format!("@{name}")
    } else {
        name.to_string()
    };
    if dual {
        line.push_str(" ^");
    }
    line
}

fn parenthetical_line(text: &str) -> String {
    let text = text.trim();
    if text.starts_with('(') {
        text.to_string()
    } else {
        format!("({text})")
    }
}

fn dialogue_lines(text: &str) -> String {
    text.lines()
        .map(|line| if line.trim().is_empty() { "  " } else { line })
        .collect::<Vec<_>>()
        .join("\n")
}

fn transition_line(text: &str) -> String {
    let text = text.trim();
    if text.ends_with("TO:") && !text.chars().any(char::is_lowercase) {
        text.to_string()
    } else {
        format!(">{text}")
    }
}

fn centered_lines(text: &str) -> String {
    text.lines()
        .map(|line| format!("> {} <", line.trim()))
        .collect::<Vec<_>>()
        .join("\n")
}

fn action_lines(text: &str) -> String {
    let first = text.lines().next().unwrap_or("").trim();
    let marker = first.starts_with(['!', '@', '.', '>', '~', '#', '=']);
    let upper = first.chars().any(char::is_alphabetic) && !first.chars().any(char::is_lowercase);
    if marker || upper || is_scene_heading(first) {
        format!("!{text}")
    } else {
        text.to_string()
    }
}

fn is_scene_heading(text: &str) -> bool {
    let upper = text.trim_start().to_ascii_uppercase();
    SCENE_PREFIXES.iter().any(|prefix| {
        upper.starts_with(prefix)
            && matches!(upper.as_bytes().get(prefix.len()), Some(b'.') | Some(b' '))
    })
}

fn runs_text(runs: &[Run]) -> String {
    let mut merged: Vec<Run> = Vec::new();
    for run in runs {
        match merged.last_mut() {
            Some(last)
                if last.bold == run.bold
                    && last.italic == run.italic
                    && last.underline == run.underline =>
            {
                last.text.push_str(&run.text);
            }
            _ => merged.push(run.clone()),
        }
    }
    merged.iter().map(emphasized).collect()
}

fn emphasized(run: &Run) -> String {
    let core = run.text.trim();
    if core.is_empty() || !(run.bold || run.italic || run.underline) {
        return escape(&run.text);
    }
    let start = &run.text[..run.text.len() - run.text.trim_start().len()];
    let end = &run.text[run.text.trim_end().len()..];
    let stars = "*".repeat(usize::from(run.bold) * 2 + usize::from(run.italic));
    let mut styled = format!("{stars}{}{stars}", escape(core));
    if run.underline {
        styled = format!("_{styled}_");
    }
    format!("{start}{styled}{end}")
}

fn escape(text: &str) -> String {
    let mut escaped = String::with_capacity(text.len());
    for c in text.chars() {
        if c == '*' || c == '_' {
            escaped.push('\\');
        }
        escaped.push(c);
    }
    escaped
}
