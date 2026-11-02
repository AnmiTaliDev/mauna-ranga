use ranga_core::{CharacterStat, parse_full};

fn stat(name: &str, speeches: u32, words: u32) -> CharacterStat {
    CharacterStat {
        name: name.to_string(),
        speeches,
        words,
    }
}

#[test]
fn counts_speeches_and_dialogue_words_per_character() {
    let doc = parse_full(
        "INT. ROOM - DAY\n\nSTEEL\n(quietly)\nHello there.\n\nBRICK\nHi.\n\nSTEEL (V.O.)\nOne two three.\n\n@McCoy ^\nBye now.\n",
    );
    assert_eq!(
        doc.character_stats(),
        vec![
            stat("STEEL", 2, 5),
            stat("MCCOY", 1, 2),
            stat("BRICK", 1, 1),
        ]
    );
}

#[test]
fn action_lines_are_not_dialogue() {
    let doc = parse_full("STEEL\nHello.\n\nHe walks away slowly.\n");
    assert_eq!(doc.character_stats(), vec![stat("STEEL", 1, 1)]);
}

#[test]
fn notes_inside_dialogue_do_not_end_the_speech() {
    let doc = parse_full("STEEL\nHello [[a note]] there friend.\n");
    assert_eq!(doc.character_stats(), vec![stat("STEEL", 1, 3)]);
}

#[test]
fn empty_document_has_no_characters() {
    assert!(parse_full("").character_stats().is_empty());
}
