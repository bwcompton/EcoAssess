'addUserBasemap' <- function(map, selected, poly) {
   
   # Add user shapefile to basemap
   # Arguments:
   #     map         Leaflet map object
   #     selected    TRUE if displaying user map is selected
   #     poly        use shapefile
   # Result:
   #     map         Leaflet map object
   # Data source:
   #     from DSL dataset
   # B. Compton, 29 Jul 2024
   

   
   if(selected) 
      map <- addPolygons(map, data = poly, group = 'usermap', weight = 2, color = 'black', 
                         fillOpacity = 0)
   else 
      clearGroup(map, group = 'usermap')
   
   map
}

