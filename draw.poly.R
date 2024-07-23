'draw.poly' <- function(poly) {
   
   # draw.poly
   # Plot uploaded polygon in Leaflet and zoom to it
   # Arguments:
   #     poly      sf polygon object
   # B. Compton, 7 May 2024
   

   
   box <- as.list(st_bbox(poly))
   leafletProxy('map', data = poly) |>
      addPolygons(group = 'poly', weight = 4, color = 'purple', fillOpacity = 0) |>
      fitBounds(lat1 = box$ymin, lat2 = box$ymax, lng1 = box$xmin, lng2 = box$xmax)
}