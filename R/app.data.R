# app.data.R - app-level constants, layers metadata, and GeoServer endpoints.
# Auto-loaded from R/ at startup so it's visible to every helper (and to
# make.ui / make.server). See app.R for the minimal entry point.
# B. Compton



home <- c(-75, 42)            # center of NER (approx)
zoom <- 6

# Layers on GeoServer (4 ecoConnect layers, 4 IEI layers, and the state-HuC index)
layers <- data.frame(
   which = c('connect', 'connect', 'connect', 'connect', 'iei', 'iei', 'iei', 'iei', 'shindex', 'template'),
   best.prob = c(rep(0.75, 4), rep(0.5, 4), NA, NA),
   workspaces = c('ecoConnect', 'ecoConnect', 'ecoConnect', 'ecoConnect', 'IEI', 'IEI', 'IEI', 'IEI', 'ecoConnect', 'ecoConnect'),
   server.names = c('Forest_fowet', 'Ridgetop', 'Nonfo_wet', 'LR_floodplain_forest', 'iei_regional', 'iei_state', 'iei_ecoregion', 'iei_huc6', 'shindex', 'template'),
   pretty.names = c('Forests', 'Ridgetops', 'Wetlands', 'Floodplain forests', 'Region', 'State', 'Ecoregion', 'Watershed', '', ''),
   radio.names = c('Forests', 'Ridgetops', 'Wetlands', 'Floodplain forests',
                   'Regional', 'State', 'Ecoregion', 'Watershed', '', ''))

full.layer.names <- paste0(layers$workspaces, ':', layers$server.names)       # we'll need these for addWMSTiles

geoserver <- list(
   primary = 'https://umassdsl.webgis1.com/geoserver/',                       # AcuGIS WMS (add 'wms') and WCS server
   fallback = 'https://marsh01.ecs.umass.edu/geoserver/'                      # MassMarsh WMS (add 'wms') and WCS server (currently fallback, as it's slow without SSD RAID)
)

osm_email <- readChar(f <- 'www/osm_email.txt', file.info(f)$size)
