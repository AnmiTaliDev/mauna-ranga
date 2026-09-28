use std::fmt::Write;

use ranga_core::{Document, ElementKind, Run};

const CENTERED_TITLE_KEYS: [&str; 5] = ["title", "credit", "author", "authors", "source"];

struct Paragraph {
    kind: &'static str,
    number: Option<String>,
    alignment: Option<&'static str>,
    starts_new_page: bool,
    runs: Vec<Run>,
    dual: Vec<Paragraph>,
}

impl Paragraph {
    fn new(kind: &'static str, runs: Vec<Run>) -> Self {
        Paragraph {
            kind,
            number: None,
            alignment: None,
            starts_new_page: false,
            runs,
            dual: Vec::new(),
        }
    }
}

pub fn export_fdx(doc: &Document) -> String {
    let source = doc.source();
    let mut paragraphs: Vec<Paragraph> = Vec::new();
    let mut new_page = false;
    let mut in_dialogue = false;
    let mut last_character: Option<usize> = None;
    let mut dual_start: Option<usize> = None;

    for element in doc.elements() {
        let kind = &element.kind;
        if *kind == ElementKind::PageBreak {
            new_page = true;
            continue;
        }
        if !kind.is_printed() {
            continue;
        }
        let dialogue_part = matches!(
            kind,
            ElementKind::Parenthetical | ElementKind::Dialogue | ElementKind::Lyric
        );
        if !(in_dialogue && dialogue_part) {
            close_dual(&mut paragraphs, &mut dual_start);
        }
        let runs = trim_runs(element.runs(source), *kind == ElementKind::Action);
        let mut paragraph = match kind {
            ElementKind::SceneHeading { number } => Paragraph {
                number: number.clone(),
                ..Paragraph::new("Scene Heading", runs)
            },
            ElementKind::Character { dual, .. } => {
                if *dual {
                    dual_start = last_character;
                }
                last_character = Some(paragraphs.len());
                Paragraph::new("Character", runs)
            }
            ElementKind::Parenthetical => Paragraph::new("Parenthetical", runs),
            ElementKind::Dialogue => Paragraph::new("Dialogue", runs),
            ElementKind::Lyric if in_dialogue => Paragraph::new("Dialogue", runs),
            ElementKind::Transition => Paragraph::new("Transition", runs),
            ElementKind::Centered => Paragraph {
                alignment: Some("Center"),
                ..Paragraph::new("Action", runs)
            },
            _ => Paragraph::new("Action", runs),
        };
        in_dialogue =
            matches!(kind, ElementKind::Character { .. }) || (in_dialogue && dialogue_part);
        if !in_dialogue {
            last_character = None;
        }
        paragraph.starts_new_page = std::mem::take(&mut new_page);
        paragraphs.push(paragraph);
    }
    close_dual(&mut paragraphs, &mut dual_start);

    let mut out = String::new();
    out.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n");
    out.push_str("<FinalDraft DocumentType=\"Script\" Template=\"No\" Version=\"1\">\n\n");
    out.push_str("  <Content>\n");
    for paragraph in &paragraphs {
        write_paragraph(&mut out, paragraph, 4);
    }
    out.push_str("  </Content>\n");

    if let Some(title_page) = doc.title_page() {
        out.push_str("\n  <TitlePage>\n    <Content>\n");
        for entry in &title_page.entries {
            let alignment = if CENTERED_TITLE_KEYS.contains(&entry.key.to_lowercase().as_str()) {
                "Center"
            } else {
                "Left"
            };
            for value in &entry.values {
                let paragraph = Paragraph {
                    alignment: Some(alignment),
                    ..Paragraph::new("", value.runs(source))
                };
                write_paragraph(&mut out, &paragraph, 6);
            }
        }
        out.push_str("    </Content>\n  </TitlePage>\n");
    }
    out.push_str("</FinalDraft>\n");
    out
}

fn close_dual(paragraphs: &mut Vec<Paragraph>, dual_start: &mut Option<usize>) {
    if let Some(start) = dual_start.take() {
        let dual: Vec<Paragraph> = paragraphs.drain(start..).collect();
        paragraphs.push(Paragraph {
            dual,
            ..Paragraph::new("General", Vec::new())
        });
    }
}

fn trim_runs(mut runs: Vec<Run>, keep_indent: bool) -> Vec<Run> {
    if !keep_indent && let Some(first) = runs.first_mut() {
        first.text = first.text.trim_start().to_string();
    }
    if let Some(last) = runs.last_mut() {
        last.text = last.text.trim_end().to_string();
    }
    runs.retain(|run| !run.text.is_empty());
    runs
}

fn write_paragraph(out: &mut String, paragraph: &Paragraph, indent: usize) {
    let pad = " ".repeat(indent);
    out.push_str(&pad);
    out.push_str("<Paragraph");
    if let Some(alignment) = paragraph.alignment {
        let _ = write!(out, " Alignment=\"{alignment}\"");
    }
    if let Some(number) = &paragraph.number {
        let _ = write!(out, " Number=\"{}\"", escape(number));
    }
    if paragraph.starts_new_page {
        out.push_str(" StartsNewPage=\"Yes\"");
    }
    if !paragraph.kind.is_empty() {
        let _ = write!(out, " Type=\"{}\"", paragraph.kind);
    }
    out.push_str(">\n");
    if paragraph.dual.is_empty() {
        for run in &paragraph.runs {
            write_text(out, run, indent + 2);
        }
    } else {
        let _ = writeln!(out, "{pad}  <DualDialogue>");
        for inner in &paragraph.dual {
            write_paragraph(out, inner, indent + 4);
        }
        let _ = writeln!(out, "{pad}  </DualDialogue>");
    }
    let _ = writeln!(out, "{pad}</Paragraph>");
}

fn write_text(out: &mut String, run: &Run, indent: usize) {
    let styles: Vec<&str> = [
        (run.bold, "Bold"),
        (run.italic, "Italic"),
        (run.underline, "Underline"),
    ]
    .into_iter()
    .filter_map(|(on, name)| on.then_some(name))
    .collect();
    let pad = " ".repeat(indent);
    if styles.is_empty() {
        let _ = writeln!(out, "{pad}<Text>{}</Text>", escape(&run.text));
    } else {
        let _ = writeln!(
            out,
            "{pad}<Text Style=\"{}\">{}</Text>",
            styles.join("+"),
            escape(&run.text)
        );
    }
}

fn escape(text: &str) -> String {
    let mut escaped = String::with_capacity(text.len());
    for c in text.chars() {
        match c {
            '&' => escaped.push_str("&amp;"),
            '<' => escaped.push_str("&lt;"),
            '>' => escaped.push_str("&gt;"),
            '"' => escaped.push_str("&quot;"),
            '\'' => escaped.push_str("&apos;"),
            c => escaped.push(c),
        }
    }
    escaped
}
