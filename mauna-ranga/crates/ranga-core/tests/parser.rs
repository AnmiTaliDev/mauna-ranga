use ranga_core::{Document, ElementKind, InlineKind, parse_full, plain_text};

fn kinds(doc: &Document) -> Vec<ElementKind> {
    doc.elements().iter().map(|e| e.kind.clone()).collect()
}

fn visible(doc: &Document, index: usize) -> String {
    plain_text(&doc.elements()[index].runs(doc.source()))
}

#[test]
fn scene_heading_with_prefixes_and_number() {
    for heading in [
        "INT. HOUSE - DAY",
        "EXT. BRICK'S POOL - DAY",
        "EST. CITY",
        "INT./EXT. CAR - NIGHT",
        "INT/EXT CAR - NIGHT",
        "I/E. CAR - NIGHT",
        "ext. brick's pool - day",
    ] {
        let doc = parse_full(&format!("{heading}\n\nAction.\n"));
        assert_eq!(
            doc.elements()[0].kind,
            ElementKind::SceneHeading { number: None },
            "{heading}"
        );
    }

    let doc = parse_full("INT. HOUSE - DAY #1A#\n");
    assert_eq!(
        doc.elements()[0].kind,
        ElementKind::SceneHeading {
            number: Some("1A".to_string())
        }
    );
    assert_eq!(visible(&doc, 0).trim(), "INT. HOUSE - DAY");
}

#[test]
fn scene_heading_needs_blank_line_after() {
    let doc = parse_full("INT. HOUSE - DAY\nShe waits.\n");
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Character {
                extension: None,
                dual: false
            },
            ElementKind::Dialogue
        ]
    );
}

#[test]
fn forced_scene_heading() {
    let doc = parse_full("Before.\n\n.SNIPER SCOPE POV\n\n...where it ends.\n");
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Action,
            ElementKind::SceneHeading { number: None },
            ElementKind::Action
        ]
    );
    assert_eq!(visible(&doc, 1), "SNIPER SCOPE POV");
}

#[test]
fn action_keeps_lines_together() {
    let doc = parse_full("And then there's a long beat.\nLonger than is funny.\n");
    assert_eq!(kinds(&doc), vec![ElementKind::Action]);
    assert_eq!(doc.elements()[0].words, 10);
}

#[test]
fn forced_action() {
    let doc = parse_full("!SCANNING THE AISLES...\nWhere is that pit boss?\n");
    assert_eq!(kinds(&doc), vec![ElementKind::Action]);
    assert!(visible(&doc, 0).starts_with("SCANNING"));
}

#[test]
fn character_dialogue_parenthetical() {
    let doc = parse_full("STEEL\n(starting the engine)\nSo much for retirement!\n");
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Character {
                extension: None,
                dual: false
            },
            ElementKind::Parenthetical,
            ElementKind::Dialogue
        ]
    );
}

#[test]
fn character_extensions_and_dual() {
    let doc =
        parse_full("MOM (O. S.)\nLuke!\n\nHANS (on the radio)\nWhat?\n\nSTEEL ^\nScrew it.\n");
    let characters: Vec<ElementKind> = doc
        .elements()
        .iter()
        .filter(|e| matches!(e.kind, ElementKind::Character { .. }))
        .map(|e| e.kind.clone())
        .collect();
    assert_eq!(
        characters,
        vec![
            ElementKind::Character {
                extension: Some("(O. S.)".to_string()),
                dual: false
            },
            ElementKind::Character {
                extension: Some("(on the radio)".to_string()),
                dual: false
            },
            ElementKind::Character {
                extension: None,
                dual: true
            },
        ]
    );
}

#[test]
fn forced_character_keeps_case() {
    let doc = parse_full("@McCLANE\nYippie ki-yay!\n");
    assert_eq!(visible(&doc, 0), "McCLANE");
    assert_eq!(doc.elements()[1].kind, ElementKind::Dialogue);
}

#[test]
fn character_needs_a_letter() {
    let doc = parse_full("23\nNot dialogue.\n");
    assert_eq!(kinds(&doc), vec![ElementKind::Action]);
}

#[test]
fn dialogue_with_two_space_line() {
    let doc = parse_full("DEALER\nTen.\n  \nHit or stand sir?\n");
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Character {
                extension: None,
                dual: false
            },
            ElementKind::Dialogue
        ]
    );
}

#[test]
fn transitions() {
    let doc = parse_full("Before.\n\nCUT TO:\n\n>Burn to White.\n\nCUT TO: \n");
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Action,
            ElementKind::Transition,
            ElementKind::Transition,
            ElementKind::Action
        ]
    );
}

#[test]
fn centered_text() {
    let doc = parse_full("> THE END <\n");
    assert_eq!(kinds(&doc), vec![ElementKind::Centered]);
    assert_eq!(visible(&doc, 0).trim(), "THE END");
}

#[test]
fn page_break() {
    let doc = parse_full("One.\n\n===\n\nTwo.\n");
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Action,
            ElementKind::PageBreak,
            ElementKind::Action
        ]
    );
}

#[test]
fn sections_and_synopsis() {
    let doc = parse_full("# Act\n\n## Sequence\n\n= Set up the story.\n");
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Section { level: 1 },
            ElementKind::Section { level: 2 },
            ElementKind::Synopsis
        ]
    );
    assert_eq!(doc.word_count(), 0);
}

#[test]
fn notes() {
    let doc = parse_full("[[It was supposed to be Vietnamese.]]\n\nHe waits[[names?]] here.\n");
    assert_eq!(kinds(&doc), vec![ElementKind::Note, ElementKind::Action]);
    assert_eq!(visible(&doc, 1), "He waits here.");
    assert!(
        doc.elements()[1]
            .inlines
            .iter()
            .any(|i| i.kind == InlineKind::Note)
    );
}

#[test]
fn multi_line_note() {
    let doc = parse_full("[[This section needs work.\nEither that, or I need coffee.]]\n");
    assert_eq!(kinds(&doc), vec![ElementKind::Note]);
}

#[test]
fn boneyard_spans_blank_lines() {
    let doc = parse_full(
        "CUT TO:\n/*\nINT. GARAGE - DAY\n\nThey speed off.\n*/\nEXT. MANSION - DAY\n\nA man.\n",
    );
    assert_eq!(
        kinds(&doc),
        vec![
            ElementKind::Transition,
            ElementKind::Boneyard,
            ElementKind::SceneHeading { number: None },
            ElementKind::Action
        ]
    );
    assert_eq!(doc.word_count(), 2 + 3 + 2);
}

#[test]
fn lyrics() {
    let doc = parse_full("~Willy Wonka! Willy Wonka!\n~Everybody give a cheer!\n");
    assert_eq!(kinds(&doc), vec![ElementKind::Lyric]);
    assert_eq!(
        visible(&doc, 0),
        "Willy Wonka! Willy Wonka!\nEverybody give a cheer!"
    );
}

#[test]
fn title_page() {
    let doc = parse_full(
        "Title:\n    _**BRICK & STEEL**_\nCredit: Written by\nAuthor: Stu Maschwitz\nDraft date: 1/20/2012\n\nEXT. PATIO - DAY\n",
    );
    let page = doc.title_page().expect("title page");
    let keys: Vec<&str> = page.entries.iter().map(|e| e.key.as_str()).collect();
    assert_eq!(keys, vec!["Title", "Credit", "Author", "Draft date"]);
    let title = &page.entry("title").expect("title").values[0];
    let runs = title.runs(doc.source());
    assert_eq!(plain_text(&runs), "BRICK & STEEL");
    assert!(runs.iter().all(|r| r.bold && r.underline));
    assert_eq!(
        kinds(&doc),
        vec![ElementKind::SceneHeading { number: None }]
    );
}

#[test]
fn emphasis() {
    let doc = parse_full("*italics* **bold** ***both*** _under_ and _an *inner* phrase_\n");
    let runs = doc.elements()[0].runs(doc.source());
    let styled = |text: &str| runs.iter().find(|r| r.text == text).cloned();
    let italic = styled("italics").expect("italics");
    assert!(italic.italic && !italic.bold);
    let bold = styled("bold").expect("bold");
    assert!(bold.bold && !bold.italic);
    let both = styled("both").expect("both");
    assert!(both.bold && both.italic);
    let inner = styled("inner").expect("inner");
    assert!(inner.italic && inner.underline);
}

#[test]
fn emphasis_rules_from_spec() {
    let escaped = parse_full("EXT. VAULT - NIGHT\n\nSteel enters the code: **\\*9765\\***\n");
    assert_eq!(visible(&escaped, 1), "Steel enters the code: *9765*");

    let spaced = parse_full("He dialed *69 and then *23, and then hung up.\n");
    assert!(
        spaced.elements()[0]
            .runs(spaced.source())
            .iter()
            .all(|r| !r.italic)
    );

    let across = parse_full("Brick and Steel *share a look.\nThis is going to be BAD.*\n");
    assert!(
        across.elements()[0]
            .runs(across.source())
            .iter()
            .all(|r| !r.italic)
    );
}

#[test]
fn word_count_skips_markup() {
    let doc = parse_full(
        "INT. HOUSE - DAY #1#\n\n**Bold** words /* hidden */ here[[note text]].\n\n# Section words\n",
    );
    assert_eq!(doc.word_count(), 3 + 3);
}
