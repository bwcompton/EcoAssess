'addBoundaries' <- function(map, selected) {
   
   # Add state and county boundaries to map
   # Arguments:
   #     map         Leaflet map object
   #     selected    TRUE if displaying boundaries is selected
   # Result:
   #     map         Leaflet map object
   # Data source:
   #     from DSL dataset
   # B. Compton, 24 Jul 2024
   
   
   
   if(selected) 
      map <- addWMSTiles(map, 'https://umassdsl.webgis1.com/geoserver/wms', 
                         layers = list('boundaries:counties', 'boundaries:states'), 
                         layerId = 'boundaries',
                         options = WMSTileOptions(transparent = TRUE, format = 'image/png'))
   else 
      removeTiles(map, layerId = 'boundaries')

   map
}
