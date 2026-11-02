use ranga_layout::PaperSize as LayoutPaper;

pub enum PaperSize {
    UsLetter,
    A4,
}

impl From<PaperSize> for LayoutPaper {
    fn from(paper: PaperSize) -> Self {
        match paper {
            PaperSize::UsLetter => LayoutPaper::UsLetter,
            PaperSize::A4 => LayoutPaper::A4,
        }
    }
}
