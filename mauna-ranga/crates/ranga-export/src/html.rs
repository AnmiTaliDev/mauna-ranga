use std::fmt::Write;

use ranga_core::{Document, ElementKind, Run, plain_text};

use crate::runs::{escape, trim_runs};

const CENTERED_TITLE_KEYS: [&str; 5] = ["title", "credit", "author", "authors", "source"];
const STYLE: &str = "body{font-family:'Courier Prime','Courier New',Courier,monospace;font-size:12pt;line-height:1;max-width:6in;margin:1in auto}p,h2{margin:0}h2{font-size:inherit;font-weight:bold;margin-top:2em}p{margin-top:1em}.character{margin:1em 0 0 2in}.dialogue-block p{margin-top:0}.dialogue{margin-left:1in;margin-right:1.5in}.parenthetical{margin-left:1.5in;margin-right:2in}.transition{text-align:right}.centered,.title-page .center{text-align:center}.dual{display:flex;gap:0.2in}.dual .dialogue-block{flex:1}.dual .character{margin-left:1in}.dual .dialogue{margin-left:0;margin-right:0}.dual .parenthetical{margin-left:0.4in;margin-right:0.4in}.title-page{margin-bottom:4em}.title-page .corner{margin-top:0}.page-break{border:0;border-top:1px dashed #999;margin:2em 0}@media print{.page-break{page-break-after:always;border:0}}";

enum Block {
    Html(String),
    Dialogue { html: String, dual: bool },
}

pub fn export_html(doc: &Document) -> String {
    let source = doc.source();
    let mut blocks: Vec<Block> = Vec::new();
    let mut in_dialogue = false;
    for element in doc.elements() {
        let kind = &element.kind;
        if *kind == ElementKind::PageBreak {
            blocks.push(Block::Html("<hr class=\"page-break\">\n".to_string()));
            in_dialogue = false;
            continue;
        }
        if !kind.is_printed() {
            continue;
        }
        let runs = trim_runs(element.runs(source), *kind == ElementKind::Action);
        let content = runs_html(&runs);
        let dialogue_part = matches!(
            kind,
            ElementKind::Parenthetical | ElementKind::Dialogue | ElementKind::Lyric
        );
        if in_dialogue
            && dialogue_part
            && let Some(Block::Dialogue { html, .. }) = blocks.last_mut()
        {
            let class = if *kind == ElementKind::Parenthetical {
                "parenthetical"
            } else {
                "dialogue"
            };
            let _ = writeln!(html, "<p class=\"{class}\">{content}</p>");
            continue;
        }
        in_dialogue = false;
        match kind {
            ElementKind::Character { dual, .. } => {
                in_dialogue = true;
                blocks.push(Block::Dialogue {
                    html: format!("<p class=\"character\">{content}</p>\n"),
                    dual: *dual,
                });
            }
            ElementKind::SceneHeading { number } => {
                let attribute = number.as_ref().map_or_else(String::new, |number| {
                    format!(" data-scene-number=\"{}\"", escape(number))
                });
                blocks.push(Block::Html(format!(
                    "<h2 class=\"scene-heading\"{attribute}>{content}</h2>\n"
                )));
            }
            ElementKind::Transition => {
                blocks.push(Block::Html(format!(
                    "<p class=\"transition\">{content}</p>\n"
                )));
            }
            ElementKind::Centered => {
                blocks.push(Block::Html(format!(
                    "<p class=\"centered\">{content}</p>\n"
                )));
            }
            _ => {
                blocks.push(Block::Html(format!("<p class=\"action\">{content}</p>\n")));
            }
        }
    }

    let mut body = String::new();
    if let Some(page) = doc.title_page() {
        body.push_str("<section class=\"title-page\">\n");
        for entry in &page.entries {
            let class = if CENTERED_TITLE_KEYS.contains(&entry.key.to_lowercase().as_str()) {
                "center"
            } else {
                "corner"
            };
            for value in &entry.values {
                let content = runs_html(&value.runs(source));
                let _ = writeln!(body, "<p class=\"{class}\">{content}</p>");
            }
        }
        body.push_str("</section>\n");
    }
    let mut index = 0;
    while index < blocks.len() {
        match (&blocks[index], blocks.get(index + 1)) {
            (
                Block::Dialogue { html: first, .. },
                Some(Block::Dialogue {
                    html: second,
                    dual: true,
                }),
            ) => {
                let _ = write!(
                    body,
                    "<div class=\"dual\">\n<div class=\"dialogue-block\">\n{first}</div>\n<div class=\"dialogue-block\">\n{second}</div>\n</div>\n"
                );
                index += 2;
            }
            (Block::Dialogue { html, .. }, _) => {
                let _ = write!(body, "<div class=\"dialogue-block\">\n{html}</div>\n");
                index += 1;
            }
            (Block::Html(html), _) => {
                body.push_str(html);
                index += 1;
            }
        }
    }

    let title = doc
        .title_page()
        .and_then(|page| page.entry("title"))
        .map(|entry| {
            entry
                .values
                .iter()
                .map(|value| plain_text(&value.runs(source)))
                .collect::<Vec<_>>()
                .join(" ")
        })
        .filter(|title| !title.trim().is_empty())
        .unwrap_or_else(|| "Screenplay".to_string());
    format!(
        "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<title>{}</title>\n<style>{STYLE}</style>\n</head>\n<body>\n{body}</body>\n</html>\n",
        escape(&title)
    )
}

fn runs_html(runs: &[Run]) -> String {
    let mut out = String::new();
    for run in runs {
        let mut open = String::new();
        let mut close = String::new();
        if run.bold {
            open.push_str("<strong>");
            close.insert_str(0, "</strong>");
        }
        if run.italic {
            open.push_str("<em>");
            close.insert_str(0, "</em>");
        }
        if run.underline {
            open.push_str("<u>");
            close.insert_str(0, "</u>");
        }
        out.push_str(&open);
        out.push_str(&escape(&run.text));
        out.push_str(&close);
    }
    out
}
