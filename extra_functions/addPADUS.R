'addPADUS' <- function(map, selected, zoom, minzoom = 11) {
   
   # Add USGS's PAD-US open space data from ESRI servers to map
   # Arguments:
   #     map         Leaflet map object
   #     selected    TRUE if displaying open space is selected
   #     zoom        current zoom level
   #     minzoom     minimum zoom level to display
   # Result:
   #     map         Leaflet map object
   # Data source:
   #     https://www.usgs.gov/programs/gap-analysis-project/science/pad-us-web-services
   #     WMS version is https://www.sciencebase.gov/catalogMaps/mapping/ows/65294599d34e44db0e2ed7cf?service=wms&request=getcapabilities&version=1.3.0
   # B. Compton, 23 Jul 2024
   
   
   
   if(selected)
      map <- addEsriFeatureLayer(map, url = 'https://services.arcgis.com/v01gqwM5QqNysAAi/arcgis/rest/services/PADUS_Protection_Status_by_GAP_Status_Code/FeatureServer/0', 
                                 layerId = 'PAD-US', options = featureLayerOptions(minZoom = minzoom),
                                 color = '#8B0A50', weight = 2, fill = FALSE)
   else
      removeGeoJSON(map, layerId = 'PAD-US')
   
   map
}
