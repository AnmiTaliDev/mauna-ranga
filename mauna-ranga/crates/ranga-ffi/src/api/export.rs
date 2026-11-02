use ranga_export::{PdfFonts, PdfOptions, export_fdx as write_fdx, export_pdf as write_pdf};
use ranga_layout::{PageConfig, paginate};

use crate::api::document::DocumentHandle;

pub struct FontFiles {
    pub regular: Vec<u8>,
    pub bold: Vec<u8>,
    pub italic: Vec<u8>,
    pub bold_italic: Vec<u8>,
}

pub struct PdfSettings {
    pub title_page: bool,
    pub page_numbers: bool,
    pub watermark: String,
}

pub async fn export_pdf(
    handle: &DocumentHandle,
    fonts: FontFiles,
    settings: PdfSettings,
) -> Result<Vec<u8>, String> {
    let document = handle.current()?;
    let config = PageConfig::default();
    let pages = paginate(&document, &config);
    let fonts = PdfFonts {
        regular: &fonts.regular,
        bold: &fonts.bold,
        italic: &fonts.italic,
        bold_italic: &fonts.bold_italic,
    };
    let options = PdfOptions {
        title_page: settings.title_page,
        page_numbers: settings.page_numbers,
        watermark: Some(settings.watermark),
    };
    write_pdf(&document, &pages, &config, &fonts, &options).map_err(|error| error.to_string())
}

pub async fn export_fdx(handle: &DocumentHandle) -> Result<String, String> {
    let document = handle.current()?;
    Ok(write_fdx(&document))
}
