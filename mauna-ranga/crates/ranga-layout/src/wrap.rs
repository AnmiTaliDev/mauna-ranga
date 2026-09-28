use ranga_core::Run;

#[derive(Clone, Copy, PartialEq)]
struct Style {
    bold: bool,
    italic: bool,
    underline: bool,
}

pub(crate) struct WrapOptions {
    pub width: usize,
    pub keep_indent: bool,
    pub uppercase: bool,
}

pub(crate) fn wrap(runs: &[Run], options: &WrapOptions) -> Vec<Vec<Run>> {
    let mut hard_lines: Vec<Vec<(char, Style)>> = Vec::new();
    let mut current: Vec<(char, Style)> = Vec::new();
    for run in runs {
        let style = Style {
            bold: run.bold,
            italic: run.italic,
            underline: run.underline,
        };
        for c in run.text.chars() {
            match c {
                '\n' => hard_lines.push(std::mem::take(&mut current)),
                '\r' => {}
                '\t' => current.extend([(' ', style); 4]),
                c if options.uppercase => current.extend(c.to_uppercase().map(|u| (u, style))),
                c => current.push((c, style)),
            }
        }
    }
    hard_lines.push(current);

    let mut lines = Vec::new();
    for mut chars in hard_lines {
        while chars.last().is_some_and(|(c, _)| c.is_whitespace()) {
            chars.pop();
        }
        if !options.keep_indent {
            let lead = chars.iter().take_while(|(c, _)| c.is_whitespace()).count();
            chars.drain(..lead);
        }
        for piece in break_line(&chars, options.width) {
            lines.push(to_runs(piece));
        }
    }
    lines
}

fn break_line(chars: &[(char, Style)], width: usize) -> Vec<&[(char, Style)]> {
    let mut pieces = Vec::new();
    let mut start = 0;
    while chars.len() - start > width {
        let space = (start + 1..=start + width)
            .rev()
            .find(|&k| chars[k].0 == ' ');
        let stop = space.unwrap_or(start + width);
        let mut end = stop;
        while end > start && chars[end - 1].0 == ' ' {
            end -= 1;
        }
        pieces.push(&chars[start..end]);
        start = stop;
        while start < chars.len() && chars[start].0 == ' ' {
            start += 1;
        }
    }
    pieces.push(&chars[start..]);
    pieces
}

fn to_runs(chars: &[(char, Style)]) -> Vec<Run> {
    let mut runs: Vec<Run> = Vec::new();
    for &(c, style) in chars {
        match runs.last_mut() {
            Some(run)
                if run.bold == style.bold
                    && run.italic == style.italic
                    && run.underline == style.underline =>
            {
                run.text.push(c)
            }
            _ => runs.push(Run {
                text: c.to_string(),
                bold: style.bold,
                italic: style.italic,
                underline: style.underline,
            }),
        }
    }
    runs
}
