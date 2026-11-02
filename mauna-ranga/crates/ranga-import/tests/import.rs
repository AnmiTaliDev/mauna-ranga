use ranga_core::{Document, ElementKind, parse_full, plain_text};
use ranga_export::export_fdx;
use ranga_import::{ImportError, import_fdx};

const SAMPLE: &str = "Title: _**BRICK & STEEL**_\nAuthor: Stu Maschwitz\nDraft date: 1/20/2012\n\nEXT. BRICK'S PATIO - DAY #1#\n\nA *gorgeous* day.\n\nSTEEL\n(beer raised)\nTo retirement.\n\nBRICK ^\nTo retirement.\n\nCUT TO:\n\n===\n\n> THE END <\n";

fn shape(doc: &Document) -> Vec<(ElementKind, String)> {
    doc.elements()
        .iter()
        .filter(|element| element.kind.is_printed())
        .map(|element| {
            (
                element.kind.clone(),
                plain_text(&element.runs(doc.source())),
            )
        })
        .collect()
}

#[test]
fn our_own_fdx_export_imports_back_to_the_same_elements() {
    let original = parse_full(SAMPLE);
    let imported = parse_full(&import_fdx(&export_fdx(&original)).expect("import"));
    assert_eq!(shape(&imported), shape(&original));
}

#[test]
fn title_page_is_rebuilt_from_centered_and_corner_paragraphs() {
    let original = parse_full(SAMPLE);
    let imported = parse_full(&import_fdx(&export_fdx(&original)).expect("import"));
    let page = imported.title_page().expect("title page");
    let title = page.entry("title").expect("title");
    assert_eq!(
        plain_text(&title.values[0].runs(imported.source())),
        "BRICK & STEEL"
    );
    let author = page.entry("author").expect("author");
    assert_eq!(
        plain_text(&author.values[0].runs(imported.source())),
        "Stu Maschwitz"
    );
}

#[test]
fn foreign_markup_is_converted_with_forced_elements() {
    let fdx = r#"<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<FinalDraft DocumentType="Script" Template="No" Version="2">
  <Content>
    <Paragraph Number="12" Type="Scene Heading"><Text>Kitchen at dawn</Text></Paragraph>
    <Paragraph Type="Action"><Text>Tom &amp; Jerry meet caf&#233;.</Text></Paragraph>
    <Paragraph Type="Action"><Text Style="Bold+Italic">Loud</Text><Text> and </Text><Text Style="Underline">quiet</Text></Paragraph>
    <Paragraph Type="Action"><Text>HE RUNS</Text></Paragraph>
    <Paragraph Type="Character"><Text>Tom</Text></Paragraph>
    <Paragraph Type="Parenthetical"><Text>whispering</Text></Paragraph>
    <Paragraph Type="Dialogue"><Text>Don't wake her.</Text></Paragraph>
    <Paragraph Type="Transition"><Text>Fade out</Text></Paragraph>
    <Paragraph Alignment="Center" StartsNewPage="Yes" Type="Action"><Text>THE END</Text></Paragraph>
    <Paragraph Type="Action"><Text/></Paragraph>
  </Content>
</FinalDraft>"#;
    let fountain = import_fdx(fdx).expect("import");
    assert_eq!(
        fountain,
        ".Kitchen at dawn #12#\n\nTom & Jerry meet café.\n\n***Loud*** and _quiet_\n\n!HE RUNS\n\n@Tom\n(whispering)\nDon't wake her.\n\n>Fade out\n\n===\n\n> THE END <\n"
    );
    let doc = parse_full(&fountain);
    let kinds: Vec<ElementKind> = doc.elements().iter().map(|e| e.kind.clone()).collect();
    assert!(matches!(kinds[0], ElementKind::SceneHeading { .. }));
    assert!(kinds.contains(&ElementKind::Transition));
    assert!(kinds.contains(&ElementKind::PageBreak));
    assert!(kinds.contains(&ElementKind::Centered));
}

#[test]
fn literal_asterisks_and_underscores_survive() {
    let fdx = "<FinalDraft><Content><Paragraph Type=\"Action\"><Text>a*b_c</Text></Paragraph></Content></FinalDraft>";
    let doc = parse_full(&import_fdx(fdx).expect("import"));
    assert_eq!(plain_text(&doc.elements()[0].runs(doc.source())), "a*b_c");
}

#[test]
fn files_that_are_not_fdx_are_rejected() {
    assert_eq!(import_fdx("<html></html>"), Err(ImportError::NotFdx));
    assert_eq!(import_fdx(""), Err(ImportError::NotFdx));
    assert!(matches!(
        import_fdx("<FinalDraft><Content></Paragraph></FinalDraft>"),
        Err(ImportError::Xml(_))
    ));
}
