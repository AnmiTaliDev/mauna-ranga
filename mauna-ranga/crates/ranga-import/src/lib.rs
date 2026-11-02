mod fdx_reader;
mod fountain_writer;

use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ImportError {
    Xml(String),
    NotFdx,
}

impl fmt::Display for ImportError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ImportError::Xml(message) => write!(f, "cannot read the FDX file: {message}"),
            ImportError::NotFdx => write!(f, "the file is not a Final Draft document"),
        }
    }
}

impl std::error::Error for ImportError {}

pub fn import_fdx(xml: &str) -> Result<String, ImportError> {
    let script = fdx_reader::read_fdx(xml)?;
    Ok(fountain_writer::write_fountain(&script))
}
