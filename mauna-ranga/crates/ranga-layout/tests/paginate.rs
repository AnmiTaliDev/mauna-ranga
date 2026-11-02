use ranga_core::{Run, parse_full, plain_text};
use ranga_layout::{Align, PageConfig, estimated_runtime_minutes, page_length, paginate};

fn text(runs: &[Run]) -> String {
    plain_text(runs)
}

fn filler(lines: usize) -> String {
    (0..lines).map(|i| format!("Line {i}.\n\n")).collect()
}

#[test]
fn default_grid_has_54_lines() {
    assert_eq!(PageConfig::default().lines_per_page(), 54);
}

#[test]
fn columns_follow_element_types() {
    let doc = parse_full("int. house - day\n\nShe waits.\n\nSTEEL\n(quietly)\nHello.\n\nCUT TO:\n");
    let pages = paginate(&doc, &PageConfig::default());
    assert_eq!(pages.len(), 1);
    let lines = &pages[0].lines;
    assert_eq!(text(&lines[0].runs), "INT. HOUSE - DAY");
    assert_eq!(lines[0].row, 0);
    assert_eq!(lines[1].row, 2);
    let character = lines
        .iter()
        .find(|l| text(&l.runs) == "STEEL")
        .expect("character");
    assert_eq!(character.column.left, 3.5);
    let paren = lines
        .iter()
        .find(|l| text(&l.runs) == "(quietly)")
        .expect("paren");
    assert_eq!(paren.column.left, 3.0);
    assert_eq!(paren.row, character.row + 1);
    let transition = lines.last().expect("transition");
    assert_eq!(text(&transition.runs), "CUT TO:");
    assert_eq!(transition.align, Align::Right);
}

#[test]
fn transition_is_right_aligned_uppercase() {
    let doc = parse_full("Before.\n\n>Burn to white.\n");
    let pages = paginate(&doc, &PageConfig::default());
    let last = pages[0].lines.last().expect("line");
    assert_eq!(last.align, Align::Right);
    assert_eq!(text(&last.runs), "BURN TO WHITE.");
}

#[test]
fn long_action_wraps_at_column_width() {
    let words = "word ".repeat(40);
    let doc = parse_full(&format!("{words}\n"));
    let pages = paginate(&doc, &PageConfig::default());
    assert!(pages[0].lines.len() > 1);
    assert!(
        pages[0]
            .lines
            .iter()
            .all(|l| text(&l.runs).chars().count() <= 60)
    );
}

#[test]
fn scene_heading_stays_with_following_action() {
    let mut source = filler(26);
    source.push_str("INT. LAST ROOM - DAY\n\nSomething happens.\n");
    let doc = parse_full(&source);
    let pages = paginate(&doc, &PageConfig::default());
    assert_eq!(pages.len(), 2);
    assert_eq!(text(&pages[1].lines[0].runs), "INT. LAST ROOM - DAY");
}

#[test]
fn page_break_starts_new_page() {
    let doc = parse_full("One.\n\n===\n\nTwo.\n");
    let pages = paginate(&doc, &PageConfig::default());
    assert_eq!(pages.len(), 2);
    assert_eq!(pages[1].number, 2);
    assert_eq!(pages[1].lines[0].row, 0);
}

#[test]
fn dialogue_splits_with_more_and_continued() {
    let mut source = filler(25);
    source.push_str("STEEL\n");
    for i in 0..10 {
        source.push_str(&format!("Line {i} of a long speech.\n"));
    }
    let doc = parse_full(&source);
    let pages = paginate(&doc, &PageConfig::default());
    assert_eq!(pages.len(), 2);
    let first = &pages[0].lines;
    assert_eq!(text(&first.last().expect("line").runs), "(MORE)");
    assert_eq!(first.last().expect("line").row, 53);
    let second = &pages[1].lines;
    assert_eq!(text(&second[0].runs), "STEEL (CONT'D)");
    assert!(pages[0].elements.end > pages[1].elements.start);
}

#[test]
fn runtime_uses_minutes_per_page() {
    let doc = parse_full(&filler(30));
    let config = PageConfig::default();
    let pages = paginate(&doc, &config);
    let length = page_length(&pages, &config);
    assert!(length > 1.0 && length < 2.0);
    let runtime = estimated_runtime_minutes(&pages, &config, 1.5);
    assert!((runtime - length * 1.5).abs() < f32::EPSILON);
    assert_eq!(estimated_runtime_minutes(&[], &config, 1.0), 0.0);
}

#[test]
fn dual_dialogue_is_laid_out_side_by_side() {
    let doc = parse_full(
        "STEEL\n(beer raised)\nTo retirement.\n\nBRICK ^\nTo retirement, and to everything after it.\n\nShe waits.\n",
    );
    let config = PageConfig::default();
    let pages = paginate(&doc, &config);
    assert_eq!(pages.len(), 1);
    let lines = &pages[0].lines;
    let find = |name: &str| {
        lines
            .iter()
            .find(|l| text(&l.runs) == name)
            .expect("line")
            .clone()
    };
    let steel = find("STEEL");
    let brick = find("BRICK");
    assert_eq!(steel.row, 0);
    assert_eq!(brick.row, 0);
    assert_eq!(steel.column, config.dual_left.character);
    assert_eq!(brick.column, config.dual_right.character);
    assert_eq!(find("(beer raised)").column, config.dual_left.parenthetical);
    let right_rows: Vec<u32> = lines
        .iter()
        .filter(|l| l.column == config.dual_right.dialogue)
        .map(|l| l.row)
        .collect();
    assert_eq!(right_rows[0], 1);
    let action = find("She waits.");
    assert_eq!(action.column, config.action);
    assert!(action.row > *right_rows.last().expect("row"));
}

#[test]
fn caret_without_preceding_dialogue_stays_in_one_column() {
    let doc = parse_full("She waits.\n\nBRICK ^\nTo retirement.\n");
    let config = PageConfig::default();
    let pages = paginate(&doc, &config);
    let brick = pages[0]
        .lines
        .iter()
        .find(|l| text(&l.runs) == "BRICK")
        .expect("line");
    assert_eq!(brick.column, config.character);
}
