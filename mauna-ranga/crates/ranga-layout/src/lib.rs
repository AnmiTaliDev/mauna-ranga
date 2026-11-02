mod config;
mod paginate;
mod runtime;
mod wrap;

pub use config::{Column, DualColumns, PageConfig};
pub use paginate::{Align, Page, PageLine, paginate};
pub use runtime::{DEFAULT_MINUTES_PER_PAGE, estimated_runtime_minutes, page_length};
