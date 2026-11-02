use ranga_import::import_fdx as read_fdx;

pub async fn import_fdx(xml: String) -> Result<String, String> {
    read_fdx(&xml).map_err(|error| error.to_string())
}
