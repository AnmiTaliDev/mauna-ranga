#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Column {
    pub left: f32,
    pub right: f32,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct DualColumns {
    pub character: Column,
    pub parenthetical: Column,
    pub dialogue: Column,
}

/// Page geometry in inches, measured from the left and top page edges.
///
/// Column indents are the `ParagraphSpec` values of the Final Draft template used by the
/// sample `.fdx` files published on fountain.io. Page size, margins and the 10 characters
/// per inch / 6 lines per inch grid of 12 pt Courier follow the common US screenplay
/// format. The top and bottom margins, the page number position, the scene number gap and the dual dialogue columns are assumptions, not
/// values taken from a normative source.
#[derive(Debug, Clone, PartialEq)]
pub struct PageConfig {
    pub page_width: f32,
    pub page_height: f32,
    pub top_margin: f32,
    pub bottom_margin: f32,
    pub page_number_top: f32,
    pub scene_number_gap: f32,
    pub font_size: f32,
    pub chars_per_inch: f32,
    pub lines_per_inch: f32,
    pub action: Column,
    pub character: Column,
    pub parenthetical: Column,
    pub dialogue: Column,
    pub transition: Column,
    pub dual_left: DualColumns,
    pub dual_right: DualColumns,
    pub scene_heading_space: u32,
    pub element_space: u32,
    pub more_label: String,
    pub continued_label: String,
}

impl Default for PageConfig {
    fn default() -> Self {
        PageConfig {
            page_width: 8.5,
            page_height: 11.0,
            top_margin: 1.0,
            bottom_margin: 1.0,
            page_number_top: 0.5,
            scene_number_gap: 0.2,
            font_size: 12.0,
            chars_per_inch: 10.0,
            lines_per_inch: 6.0,
            action: Column {
                left: 1.5,
                right: 7.5,
            },
            character: Column {
                left: 3.5,
                right: 7.25,
            },
            parenthetical: Column {
                left: 3.0,
                right: 5.5,
            },
            dialogue: Column {
                left: 2.5,
                right: 6.0,
            },
            transition: Column {
                left: 5.5,
                right: 7.1,
            },
            dual_left: DualColumns {
                character: Column {
                    left: 2.5,
                    right: 4.4,
                },
                parenthetical: Column {
                    left: 1.9,
                    right: 4.0,
                },
                dialogue: Column {
                    left: 1.5,
                    right: 4.4,
                },
            },
            dual_right: DualColumns {
                character: Column {
                    left: 5.6,
                    right: 7.5,
                },
                parenthetical: Column {
                    left: 5.0,
                    right: 7.1,
                },
                dialogue: Column {
                    left: 4.6,
                    right: 7.5,
                },
            },
            scene_heading_space: 2,
            element_space: 1,
            more_label: "(MORE)".to_string(),
            continued_label: "(CONT'D)".to_string(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum PaperSize {
    #[default]
    UsLetter,
    A4,
}

impl PageConfig {
    pub fn for_paper(paper: PaperSize) -> Self {
        match paper {
            PaperSize::UsLetter => PageConfig::default(),
            PaperSize::A4 => PageConfig {
                page_width: 8.27,
                page_height: 11.69,
                bottom_margin: 1.69,
                ..PageConfig::default()
            },
        }
    }
}

impl PageConfig {
    pub fn lines_per_page(&self) -> u32 {
        ((self.page_height - self.top_margin - self.bottom_margin) * self.lines_per_inch).floor()
            as u32
    }

    pub fn line_height_pt(&self) -> f32 {
        72.0 / self.lines_per_inch
    }

    pub fn char_width_pt(&self) -> f32 {
        72.0 / self.chars_per_inch
    }

    pub fn columns_in(&self, column: Column) -> usize {
        (((column.right - column.left) * self.chars_per_inch).floor() as usize).max(1)
    }
}
