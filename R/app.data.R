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


# Massachusetts parcels (MA mode only) -- MassGIS L3 assessor parcels, served
# from the ArcGIS FeatureServer. See R/get.parcels.R and R/parcel.server.R.
parcels.url      <- 'https://services1.arcgis.com/hGdibHYSPO59RG1h/arcgis/rest/services/Massachusetts_Property_Tax_Parcels/FeatureServer/0'
parcels.id       <- 'LOC_ID'   # MassGIS statewide unique parcel id (a string)
parcels.zoom     <- 15         # show/fetch parcels at this Leaflet zoom or closer
parcels.grid     <- 0.01       # viewport-fetch grid cell size, degrees (~0.8 km E-W in MA)
parcels.debounce <- 300        # ms to collapse rapid pan/zoom before fetching
