pub(crate) fn byte_offset(source: &str, unit: u32) -> Option<usize> {
    let mut units = 0u32;
    for (byte, c) in source.char_indices() {
        if units == unit {
            return Some(byte);
        }
        units += c.len_utf16() as u32;
        if units > unit {
            return None;
        }
    }
    (units == unit).then_some(source.len())
}

pub(crate) struct Cursor<'a> {
    source: &'a str,
    byte: usize,
    unit: u32,
}

impl<'a> Cursor<'a> {
    pub(crate) fn new(source: &'a str) -> Self {
        Cursor {
            source,
            byte: 0,
            unit: 0,
        }
    }

    pub(crate) fn unit_at(&mut self, byte: usize) -> u32 {
        self.unit += units(&self.source[self.byte..byte]);
        self.byte = byte;
        self.unit
    }
}

pub(crate) fn units(text: &str) -> u32 {
    text.chars().map(|c| c.len_utf16() as u32).sum()
}
