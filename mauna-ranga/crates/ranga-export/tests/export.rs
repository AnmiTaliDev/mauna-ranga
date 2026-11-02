use std::path::PathBuf;

use ranga_core::parse_full;
use ranga_export::{
    ExportError, PdfFonts, PdfOptions, export_fdx, export_html, export_pdf, export_text,
};
use ranga_layout::{PageConfig, PaperSize, paginate};

const SAMPLE: &str = "Title: _**BRICK & STEEL**_\nAuthor: Stu Maschwitz\nDraft date: 1/20/2012\n\nEXT. BRICK'S PATIO - DAY #1#\n\nA *gorgeous* day.\n\nSTEEL\n(beer raised)\nTo retirement.\n\nBRICK ^\nTo retirement.\n\nCUT TO:\n\n===\n\n> THE END <\n";

fn font(name: &str) -> Vec<u8> {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../../app/fonts")
        .join(name);
    std::fs::read(&path).unwrap_or_else(|_| panic!("missing {}", path.display()))
}

#[test]
fn fdx_follows_final_draft_structure() {
    let fdx = export_fdx(&parse_full(SAMPLE));
    assert!(fdx.starts_with("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n<FinalDraft DocumentType=\"Script\" Template=\"No\" Version=\"1\">"));
    assert!(fdx.contains("<Paragraph Number=\"1\" Type=\"Scene Heading\">\n      <Text>EXT. BRICK&apos;S PATIO - DAY</Text>"));
    assert!(fdx.contains("<Text Style=\"Italic\">gorgeous</Text>"));
    assert!(
        fdx.contains("<Paragraph Type=\"Parenthetical\">\n          <Text>(beer raised)</Text>")
    );
    assert!(fdx.contains("<Paragraph Type=\"Transition\">\n      <Text>CUT TO:</Text>"));
    assert!(fdx.contains("<Paragraph Alignment=\"Center\" StartsNewPage=\"Yes\" Type=\"Action\">\n      <Text>THE END</Text>"));
    assert!(fdx.contains("<Text Style=\"Bold+Underline\">BRICK &amp; STEEL</Text>"));
    assert!(fdx.trim_end().ends_with("</FinalDraft>"));
}

#[test]
fn fdx_wraps_dual_dialogue() {
    let fdx = export_fdx(&parse_full(SAMPLE));
    let start = fdx.find("<DualDialogue>").expect("dual dialogue");
    let end = fdx.find("</DualDialogue>").expect("dual dialogue end");
    let inner = &fdx[start..end];
    assert!(inner.contains("<Text>STEEL</Text>"));
    assert!(inner.contains("<Text>BRICK</Text>"));
    assert!(
        fdx[..start]
            .trim_end()
            .ends_with("<Paragraph Type=\"General\">")
    );
}

#[test]
fn pdf_has_title_page_and_body() {
    let doc = parse_full(SAMPLE);
    let config = PageConfig::default();
    let pages = paginate(&doc, &config);
    assert_eq!(pages.len(), 2);
    let (regular, bold, italic, bold_italic) = (
        font("CourierPrime-Regular.ttf"),
        font("CourierPrime-Bold.ttf"),
        font("CourierPrime-Italic.ttf"),
        font("CourierPrime-BoldItalic.ttf"),
    );
    let fonts = PdfFonts {
        regular: &regular,
        bold: &bold,
        italic: &italic,
        bold_italic: &bold_italic,
    };
    let bytes = export_pdf(&doc, &pages, &config, &fonts, &PdfOptions::default()).expect("pdf");
    assert!(bytes.starts_with(b"%PDF-"));
    assert!(bytes.len() > 1000);
}

#[test]
fn pdf_reports_bad_font() {
    let doc = parse_full(SAMPLE);
    let config = PageConfig::default();
    let pages = paginate(&doc, &config);
    let regular = font("CourierPrime-Regular.ttf");
    let fonts = PdfFonts {
        regular: &regular,
        bold: b"not a font",
        italic: &regular,
        bold_italic: &regular,
    };
    assert_eq!(
        export_pdf(&doc, &pages, &config, &fonts, &PdfOptions::default()),
        Err(ExportError::Font("bold"))
    );
}

fn export_with(options: &PdfOptions) -> Vec<u8> {
    let doc = parse_full(SAMPLE);
    let config = PageConfig::default();
    let pages = paginate(&doc, &config);
    let (regular, bold, italic, bold_italic) = (
        font("CourierPrime-Regular.ttf"),
        font("CourierPrime-Bold.ttf"),
        font("CourierPrime-Italic.ttf"),
        font("CourierPrime-BoldItalic.ttf"),
    );
    let fonts = PdfFonts {
        regular: &regular,
        bold: &bold,
        italic: &italic,
        bold_italic: &bold_italic,
    };
    export_pdf(&doc, &pages, &config, &fonts, options).expect("pdf")
}

fn page_count(bytes: &[u8]) -> usize {
    let text = String::from_utf8_lossy(bytes);
    let start = text.find("/Type/Pages/Count ").expect("page tree") + "/Type/Pages/Count ".len();
    text[start..]
        .chars()
        .take_while(char::is_ascii_digit)
        .collect::<String>()
        .parse()
        .expect("count")
}

#[test]
fn pdf_title_page_can_be_left_out() {
    let with = export_with(&PdfOptions::default());
    let without = export_with(&PdfOptions {
        title_page: false,
        ..PdfOptions::default()
    });
    assert_eq!(page_count(&with), 3);
    assert_eq!(page_count(&without), 2);
}

#[test]
fn pdf_watermark_adds_content_and_blank_text_is_ignored() {
    let plain = export_with(&PdfOptions::default());
    let marked = export_with(&PdfOptions {
        watermark: Some("CONFIDENTIAL".to_string()),
        ..PdfOptions::default()
    });
    let blank = export_with(&PdfOptions {
        watermark: Some("   ".to_string()),
        ..PdfOptions::default()
    });
    assert!(marked.len() > plain.len() + 100);
    assert_eq!(page_count(&marked), 3);
    assert!(blank.len().abs_diff(plain.len()) < 20);
}

#[test]
fn pdf_page_numbers_can_be_left_out() {
    let plain = export_with(&PdfOptions::default());
    let unnumbered = export_with(&PdfOptions {
        page_numbers: false,
        ..PdfOptions::default()
    });
    assert_eq!(page_count(&unnumbered), page_count(&plain));
    assert!(plain.len() > unnumbered.len() + 15);
}

#[test]
fn html_marks_up_elements_and_escapes_text() {
    let html = export_html(&parse_full(SAMPLE));
    assert!(html.starts_with("<!DOCTYPE html>"));
    assert!(html.contains("<title>BRICK &amp; STEEL</title>"));
    assert!(html.contains(
        "<h2 class=\"scene-heading\" data-scene-number=\"1\">EXT. BRICK&apos;S PATIO - DAY</h2>"
    ));
    assert!(html.contains("<p class=\"action\">A <em>gorgeous</em> day.</p>"));
    assert!(html.contains("<p class=\"transition\">CUT TO:</p>"));
    assert!(html.contains("<hr class=\"page-break\">"));
    assert!(html.contains("<p class=\"centered\">THE END</p>"));
    let escaped = export_html(&parse_full("He types <script>x</script> & leaves.\n"));
    assert!(escaped.contains("He types &lt;script&gt;x&lt;/script&gt; &amp; leaves."));
    assert!(!escaped.contains("<script>"));
}

#[test]
fn html_puts_dual_dialogue_in_one_container() {
    let html = export_html(&parse_full(SAMPLE));
    let start = html.find("<div class=\"dual\">").expect("dual");
    let end = html[start..].find("</div>\n</div>").expect("dual end") + start;
    let inner = &html[start..end];
    assert!(inner.contains("<p class=\"character\">STEEL</p>"));
    assert!(inner.contains("<p class=\"parenthetical\">(beer raised)</p>"));
    assert!(inner.contains("<p class=\"character\">BRICK</p>"));
    assert!(inner.find("STEEL").expect("steel") < inner.find("BRICK").expect("brick"));
}

#[test]
fn text_places_elements_in_their_columns() {
    let doc = parse_full(SAMPLE);
    let config = PageConfig::default();
    let pages = paginate(&doc, &config);
    let text = export_text(&doc, &pages, &config);
    assert_eq!(text.matches('\x0c').count(), 2);
    let lines: Vec<&str> = text.lines().collect();
    assert!(lines.contains(&"               EXT. BRICK'S PATIO - DAY"));
    assert!(lines.contains(&"               A gorgeous day."));
    assert!(
        lines
            .iter()
            .any(|line| line.ends_with("CUT TO:") && line.trim_start().len() < line.len() - 50)
    );
    assert!(
        lines
            .iter()
            .filter(|line| **line != "\x0c")
            .all(|line| *line == line.trim_end())
    );
    assert!(lines.iter().any(|line| line.trim() == "BRICK & STEEL"));
}

#[test]
fn pdf_notes_page_is_added_only_when_asked_and_notes_exist() {
    let with_notes = "INT. DEPOT - NIGHT\n\nRain [[check the sound]] falls.\n";
    let export = |source: &str, notes_page: bool| {
        let doc = parse_full(source);
        let config = PageConfig::default();
        let pages = paginate(&doc, &config);
        let (regular, bold, italic, bold_italic) = (
            font("CourierPrime-Regular.ttf"),
            font("CourierPrime-Bold.ttf"),
            font("CourierPrime-Italic.ttf"),
            font("CourierPrime-BoldItalic.ttf"),
        );
        let fonts = PdfFonts {
            regular: &regular,
            bold: &bold,
            italic: &italic,
            bold_italic: &bold_italic,
        };
        let options = PdfOptions {
            notes_page,
            ..PdfOptions::default()
        };
        page_count(&export_pdf(&doc, &pages, &config, &fonts, &options).expect("pdf"))
    };
    assert_eq!(export(with_notes, false), 1);
    assert_eq!(export(with_notes, true), 2);
    assert_eq!(export("INT. DEPOT - NIGHT\n\nNo notes here.\n", true), 1);
}

#[test]
fn pdf_page_size_follows_the_paper() {
    let export = |paper: PaperSize| {
        let doc = parse_full(SAMPLE);
        let config = PageConfig::for_paper(paper);
        let pages = paginate(&doc, &config);
        let (regular, bold, italic, bold_italic) = (
            font("CourierPrime-Regular.ttf"),
            font("CourierPrime-Bold.ttf"),
            font("CourierPrime-Italic.ttf"),
            font("CourierPrime-BoldItalic.ttf"),
        );
        let fonts = PdfFonts {
            regular: &regular,
            bold: &bold,
            italic: &italic,
            bold_italic: &bold_italic,
        };
        let bytes = export_pdf(&doc, &pages, &config, &fonts, &PdfOptions::default()).expect("pdf");
        String::from_utf8_lossy(&bytes).into_owned()
    };
    let letter = export(PaperSize::UsLetter);
    assert!(letter.contains("/MediaBox[0 0 612"));
    assert!(letter.contains("792"));
    assert!(!letter.contains("595.44"));
    let a4 = export(PaperSize::A4);
    assert!(a4.contains("/MediaBox[0 0 595.44"));
    assert!(a4.contains("841.68"));
    assert!(!a4.contains("/MediaBox[0 0 612"));
}
