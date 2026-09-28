use crate::config::PageConfig;
use crate::paginate::Page;

pub const DEFAULT_MINUTES_PER_PAGE: f32 = 1.0;

pub fn page_length(pages: &[Page], config: &PageConfig) -> f32 {
    let Some(last) = pages.last() else {
        return 0.0;
    };
    let full = (pages.len() - 1) as f32;
    full + last.rows_used as f32 / config.lines_per_page() as f32
}

pub fn estimated_runtime_minutes(
    pages: &[Page],
    config: &PageConfig,
    minutes_per_page: f32,
) -> f32 {
    page_length(pages, config) * minutes_per_page
}
