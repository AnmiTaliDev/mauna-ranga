use std::path::PathBuf;

use ranga_core::parse_full;
use ranga_export::{ExportError, PdfFonts, PdfOptions, export_fdx, export_pdf};
use ranga_layout::{PageConfig, paginate};

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
