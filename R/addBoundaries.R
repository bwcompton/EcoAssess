'addBoundaries' <- function(map, selected, geoserver, layers) {

   # addBoundaries
   # Add boundary overlay to the Leaflet map.
   # Arguments:
   #     map       Leaflet map or proxy (piped in)
   #     selected  TRUE if the show-boundaries checkbox is checked
   #     geoserver base URL of the active GeoServer
   #     layers    WMS layer list from cfg$boundary.layers: regional uses
   #               counties + states; MA uses mass_towns + mass_counties
   # Result:
   #     map with boundaries added or removed
   # B. Compton, 24 Jul 2024; layers param added 27 May 2026

   if(selected)
      map <- addWMSTiles(map, paste0(geoserver, 'wms'),
                         layers = layers,
                         layerId = 'boundaries',
                         options = WMSTileOptions(transparent = TRUE, format = 'image/png'))
   else
      removeTiles(map, layerId = 'boundaries')

   map
}
