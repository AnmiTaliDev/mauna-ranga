use quick_xml::XmlVersion;
use quick_xml::events::{BytesStart, Event};
use quick_xml::reader::Reader;

use crate::ImportError;

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Run {
    pub text: String,
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
}

#[derive(Debug, Clone, Default)]
pub(crate) struct Paragraph {
    pub kind: String,
    pub number: Option<String>,
    pub centered: bool,
    pub new_page: bool,
    pub second_dual: bool,
    pub runs: Vec<Run>,
}

pub(crate) struct Script {
    pub body: Vec<Paragraph>,
    pub title_page: Vec<Paragraph>,
}

pub(crate) fn read_fdx(xml: &str) -> Result<Script, ImportError> {
    let mut reader = Reader::from_str(xml);
    let mut body: Vec<Paragraph> = Vec::new();
    let mut title_page: Vec<Paragraph> = Vec::new();
    let mut stack: Vec<Paragraph> = Vec::new();
    let mut in_title_page = false;
    let mut dual_from: Option<usize> = None;
    let mut text_style: Option<(bool, bool, bool)> = None;
    let mut text = String::new();
    let mut found_root = false;

    loop {
        let event = reader
            .read_event()
            .map_err(|error| ImportError::Xml(error.to_string()))?;
        match event {
            Event::Start(start) => match start.name().as_ref() {
                "FinalDraft" => found_root = true,
                "TitlePage" => in_title_page = true,
                "DualDialogue" => dual_from = Some(body.len()),
                "Paragraph" => stack.push(paragraph_from(&start)?),
                "Text" => {
                    text_style = Some(style_from(&start)?);
                    text.clear();
                }
                _ => {}
            },
            Event::Empty(start) => {
                if start.name().as_ref() == "Paragraph" {
                    let paragraph = paragraph_from(&start)?;
                    finish(paragraph, in_title_page, &mut body, &mut title_page);
                }
            }
            Event::Text(content) if text_style.is_some() => {
                text.push_str(&content.xml10_content());
            }
            Event::CData(content) if text_style.is_some() => {
                text.push_str(&content.xml10_content());
            }
            Event::GeneralRef(reference) if text_style.is_some() => {
                text.push_str(&resolve_reference(&reference)?);
            }
            Event::End(end) => match end.name().as_ref() {
                "TitlePage" => in_title_page = false,
                "DualDialogue" => {
                    if let Some(from) = dual_from.take() {
                        mark_second_character(&mut body[from..]);
                    }
                }
                "Text" => {
                    if let (Some((bold, italic, underline)), Some(paragraph)) =
                        (text_style.take(), stack.last_mut())
                    {
                        paragraph.runs.push(Run {
                            text: std::mem::take(&mut text),
                            bold,
                            italic,
                            underline,
                        });
                    }
                }
                "Paragraph" => {
                    if let Some(paragraph) = stack.pop() {
                        finish(paragraph, in_title_page, &mut body, &mut title_page);
                    }
                }
                _ => {}
            },
            Event::Eof => break,
            _ => {}
        }
    }
    if !found_root {
        return Err(ImportError::NotFdx);
    }
    Ok(Script { body, title_page })
}

fn finish(
    paragraph: Paragraph,
    in_title_page: bool,
    body: &mut Vec<Paragraph>,
    title_page: &mut Vec<Paragraph>,
) {
    if in_title_page {
        title_page.push(paragraph);
    } else {
        body.push(paragraph);
    }
}

fn mark_second_character(paragraphs: &mut [Paragraph]) {
    let mut seen = 0;
    for paragraph in paragraphs {
        if paragraph.kind == "Character" {
            seen += 1;
            if seen == 2 {
                paragraph.second_dual = true;
                return;
            }
        }
    }
}

fn paragraph_from(start: &BytesStart) -> Result<Paragraph, ImportError> {
    let mut paragraph = Paragraph::default();
    for attribute in start.attributes() {
        let attribute = attribute.map_err(|error| ImportError::Xml(error.to_string()))?;
        let value = attribute
            .normalized_value(XmlVersion::Implicit1_0)
            .map_err(|error| ImportError::Xml(error.to_string()))?
            .into_owned();
        match attribute.key.as_ref() {
            "Type" => paragraph.kind = value,
            "Number" => paragraph.number = Some(value).filter(|number| !number.is_empty()),
            "Alignment" => paragraph.centered = value == "Center",
            "StartsNewPage" => paragraph.new_page = value == "Yes",
            _ => {}
        }
    }
    Ok(paragraph)
}

fn style_from(start: &BytesStart) -> Result<(bool, bool, bool), ImportError> {
    let mut style = (false, false, false);
    for attribute in start.attributes() {
        let attribute = attribute.map_err(|error| ImportError::Xml(error.to_string()))?;
        if attribute.key.as_ref() == "Style" {
            let value = attribute
                .normalized_value(XmlVersion::Implicit1_0)
                .map_err(|error| ImportError::Xml(error.to_string()))?
                .to_lowercase();
            for part in value.split('+') {
                match part.trim() {
                    "bold" => style.0 = true,
                    "italic" => style.1 = true,
                    "underline" => style.2 = true,
                    _ => {}
                }
            }
        }
    }
    Ok(style)
}

fn resolve_reference(reference: &quick_xml::events::BytesRef) -> Result<String, ImportError> {
    if let Some(c) = reference
        .resolve_char_ref()
        .map_err(|error| ImportError::Xml(error.to_string()))?
    {
        return Ok(c.to_string());
    }
    match &**reference {
        "amp" => Ok("&".to_string()),
        "lt" => Ok("<".to_string()),
        "gt" => Ok(">".to_string()),
        "quot" => Ok("\"".to_string()),
        "apos" => Ok("'".to_string()),
        other => Err(ImportError::Xml(format!("unknown entity &{other};"))),
    }
}
