use ranga_core::Document;

const INDENT: &str = "  ";

pub(crate) fn notes_lines(
    doc: &Document,
    width: usize,
    title: &str,
    before_first_scene: &str,
) -> Vec<String> {
    let notes = doc.notes();
    if notes.is_empty() {
        return Vec::new();
    }
    let mut lines = vec![title.to_string(), String::new()];
    let mut scene: Option<&Option<String>> = None;
    for (index, note) in notes.iter().enumerate() {
        if scene != Some(&note.scene) {
            if scene.is_some() {
                lines.push(String::new());
            }
            scene = Some(&note.scene);
            lines.push(
                note.scene
                    .clone()
                    .unwrap_or_else(|| before_first_scene.to_string()),
            );
        }
        let label = format!("{INDENT}{}. ", index + 1);
        let continuation = " ".repeat(label.chars().count());
        let room = width.saturating_sub(label.chars().count()).max(1);
        for (i, line) in wrap(&note.text, room).into_iter().enumerate() {
            let prefix = if i == 0 { &label } else { &continuation };
            lines.push(format!("{prefix}{line}"));
        }
    }
    lines
}

fn wrap(text: &str, width: usize) -> Vec<String> {
    let mut lines: Vec<String> = Vec::new();
    let mut current = String::new();
    for word in text.split_whitespace() {
        let mut word = word.to_string();
        while word.chars().count() > width {
            if !current.is_empty() {
                lines.push(std::mem::take(&mut current));
            }
            let head: String = word.chars().take(width).collect();
            word = word.chars().skip(width).collect();
            lines.push(head);
        }
        let needed =
            current.chars().count() + usize::from(!current.is_empty()) + word.chars().count();
        if needed > width && !current.is_empty() {
            lines.push(std::mem::take(&mut current));
        }
        if !current.is_empty() {
            current.push(' ');
        }
        current.push_str(&word);
    }
    if !current.is_empty() {
        lines.push(current);
    }
    lines
}

#[cfg(test)]
mod tests {
    use super::{notes_lines, wrap};
    use ranga_core::parse_full;

    #[test]
    fn wraps_words_and_splits_overlong_ones() {
        assert_eq!(wrap("one two three four", 9), ["one two", "three", "four"]);
        assert_eq!(wrap("abcdefghij", 4), ["abcd", "efgh", "ij"]);
    }

    #[test]
    fn groups_notes_by_scene_and_numbers_them() {
        let doc = parse_full(
            "[[First]]\n\nINT. A - DAY\n\nText [[second]] and [[third one]].\n\nEXT. B - NIGHT\n\nMore [[fourth]].\n",
        );
        assert_eq!(
            notes_lines(&doc, 40, "NOTES", "Before the first scene"),
            vec![
                "NOTES",
                "",
                "Before the first scene",
                "  1. First",
                "",
                "INT. A - DAY",
                "  2. second",
                "  3. third one",
                "",
                "EXT. B - NIGHT",
                "  4. fourth",
            ]
        );
    }

    #[test]
    fn titles_come_from_the_caller() {
        let doc = parse_full("[[Alpha]]\n");
        assert_eq!(
            notes_lines(&doc, 40, "ЗАМЕТКИ", "До первой сцены"),
            vec!["ЗАМЕТКИ", "", "До первой сцены", "  1. Alpha"]
        );
    }

    #[test]
    fn no_notes_gives_no_lines() {
        assert!(
            notes_lines(
                &parse_full("Text.\n"),
                40,
                "NOTES",
                "Before the first scene"
            )
            .is_empty()
        );
    }
}
