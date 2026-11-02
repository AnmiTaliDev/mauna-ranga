use ranga_core::{NoteEntry, parse_full};

fn note(text: &str, start: usize, scene: Option<&str>) -> NoteEntry {
    NoteEntry {
        text: text.to_string(),
        start,
        scene: scene.map(str::to_string),
    }
}

#[test]
fn collects_inline_and_block_notes_with_their_scene() {
    let source = "[[Before any scene]]\n\nINT. DEPOT - NIGHT\n\nRain [[check the sound]] falls.\n\n[[A block\nnote over two lines]]\n\nEXT. STREET - DAY\n\nSTEEL\nHello [[softer]] there.\n";
    let doc = parse_full(source);
    assert_eq!(
        doc.notes(),
        vec![
            note("Before any scene", 0, None),
            note(
                "check the sound",
                source.find("[[check").expect("note"),
                Some("INT. DEPOT - NIGHT")
            ),
            note(
                "A block note over two lines",
                source.find("[[A block").expect("note"),
                Some("INT. DEPOT - NIGHT")
            ),
            note(
                "softer",
                source.find("[[softer").expect("note"),
                Some("EXT. STREET - DAY")
            ),
        ]
    );
}

#[test]
fn a_document_without_notes_has_none() {
    assert!(parse_full("INT. ROOM - DAY\n\nText.\n").notes().is_empty());
}
