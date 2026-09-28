use std::path::PathBuf;

use ranga_core::parse_full;
use ranga_export::{ExportError, PdfFonts, export_fdx, export_pdf};
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
    let bytes = export_pdf(&doc, &pages, &config, &fonts).expect("pdf");
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
        export_pdf(&doc, &pages, &config, &fonts),
        Err(ExportError::Font("bold"))
    );
}
