use ranga_core::{EditError, InlineKind, TextEdit, parse_full};

fn scenes(count: usize) -> String {
    let mut text = String::from("Title: Test\n\n");
    for i in 0..count {
        text.push_str(&format!(
            "INT. ROOM {i} - DAY #{i}#\n\nShe looks *around* the room.\n\n@STEEL\n(*quietly*)\nThis is **scene** {i}.\n\n"
        ));
    }
    text
}

fn apply(text: &str, edit: &TextEdit) -> String {
    format!(
        "{}{}{}",
        &text[..edit.start],
        edit.replacement,
        &text[edit.end..]
    )
}

#[test]
fn edit_reparses_only_nearby_blocks() {
    let text = scenes(50);
    let mut doc = parse_full(&text);
    let before: Vec<*const _> = doc.elements().iter().map(|e| e.inlines.as_ptr()).collect();
    let total = doc.elements().len();

    let start = text.find("scene** 25").expect("scene 25") + 2;
    let edit = TextEdit {
        start,
        end: start,
        replacement: " big".to_string(),
    };
    let info = doc.reparse_range(&edit).expect("edit applies");

    assert!(!info.full);
    assert!(info.removed <= 6, "removed {}", info.removed);
    assert_eq!(info.removed, info.inserted);
    assert!(info.first > 0 && info.first + info.removed < total);
    let after: Vec<*const _> = doc.elements().iter().map(|e| e.inlines.as_ptr()).collect();
    for i in (0..info.first).chain(info.first + info.inserted..total) {
        assert!(!doc.elements()[i].inlines.is_empty());
        assert_eq!(before[i], after[i], "element {i} was rebuilt");
    }
    assert_eq!(doc, parse_full(&apply(&text, &edit)));
}

#[test]
fn suffix_ranges_are_shifted() {
    let text = scenes(3);
    let mut doc = parse_full(&text);
    let last_before = doc.elements().last().cloned().expect("elements");
    let edit = TextEdit {
        start: text.find("looks").expect("looks"),
        end: text.find("looks").expect("looks") + 5,
        replacement: "stares".to_string(),
    };
    doc.reparse_range(&edit).expect("edit applies");
    let last_after = doc.elements().last().expect("elements");
    assert_eq!(last_after.range.start, last_before.range.start + 1);
    assert_eq!(doc.text(last_after.range), "This is **scene** 2.");
}

#[test]
fn boneyard_edit_falls_back_to_full_parse() {
    let text = scenes(3);
    let mut doc = parse_full(&text);
    let start = text.find("INT. ROOM 1").expect("scene 1");
    let edit = TextEdit {
        start,
        end: start,
        replacement: "/*\n".to_string(),
    };
    let info = doc.reparse_range(&edit).expect("edit applies");
    assert!(info.full);
    let close = doc.source().find("INT. ROOM 2").expect("scene 2");
    let info = doc
        .reparse_range(&TextEdit {
            start: close,
            end: close,
            replacement: "*/\n".to_string(),
        })
        .expect("edit applies");
    assert!(info.full);
    assert_eq!(doc, parse_full(doc.source()));
}

#[test]
fn title_page_follows_edits() {
    let mut doc = parse_full("Title: One\n\nAction.\n");
    doc.reparse_range(&TextEdit {
        start: 7,
        end: 10,
        replacement: "Two words".to_string(),
    })
    .expect("edit applies");
    assert_eq!(doc, parse_full("Title: Two words\n\nAction.\n"));
    assert_eq!(doc.word_count(), 3);
}

#[test]
fn random_edits_match_full_parse() {
    let mut text = scenes(8);
    text.push_str("> THE END <\n\n/* cut\n\nINT. GONE - DAY\n*/\n\n~La la\n");
    let mut doc = parse_full(&text);
    let alphabet = [
        "a", "B", " ", "\n", "\n\n", "*", "_", "INT. ", "CUT TO:", "(", ")", "#", "=", "[[", "]]",
        "/", ">", "<", "!", "@", "~", "é", "  ",
    ];
    let mut seed: u64 = 0x5eed;
    let mut next = |bound: usize| {
        seed = seed
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        ((seed >> 33) as usize) % bound.max(1)
    };
    for _ in 0..2000 {
        let len = doc.source().len();
        let mut start = next(len + 1);
        while !doc.source().is_char_boundary(start) {
            start -= 1;
        }
        let mut end = (start + next(6)).min(len);
        while !doc.source().is_char_boundary(end) {
            end += 1;
        }
        let replacement = if next(3) == 0 {
            String::new()
        } else {
            alphabet[next(alphabet.len())].to_string()
        };
        let edit = TextEdit {
            start,
            end,
            replacement,
        };
        let expected = apply(doc.source(), &edit);
        doc.reparse_range(&edit).expect("edit applies");
        assert_eq!(doc, parse_full(&expected), "after {edit:?}");
    }
}

#[test]
fn invalid_edits_are_rejected() {
    let mut doc = parse_full("Café.\n");
    let edit = |start, end| TextEdit {
        start,
        end,
        replacement: String::new(),
    };
    assert_eq!(
        doc.reparse_range(&edit(3, 2)),
        Err(EditError::InvertedRange)
    );
    assert_eq!(doc.reparse_range(&edit(0, 99)), Err(EditError::OutOfBounds));
    assert_eq!(
        doc.reparse_range(&edit(4, 4)),
        Err(EditError::NotCharBoundary)
    );
    assert!(
        doc.elements()[0]
            .inlines
            .iter()
            .all(|i| i.kind != InlineKind::Note)
    );
}
