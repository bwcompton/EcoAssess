'scalebar' <- fucntion(map.base) {
   
   # From https://stackoverflow.com/questions/18136468/is-there-a-way-to-add-a-scale-bar-for-linear-distances-to-ggmap
   
   
   library(geosphere)
   
   
   # map.base <- get_map ...
   
   
   bb <- attr(map.base,"bb")
   sbar <- data.frame(lon.start = c(bb$ll.lon + 0.1*(bb$ur.lon - bb$ll.lon)),
                      lon.end = c(bb$ll.lon + 0.25*(bb$ur.lon - bb$ll.lon)),
                      lat.start = c(bb$ll.lat + 0.1*(bb$ur.lat - bb$ll.lat)),
                      lat.end = c(bb$ll.lat + 0.1*(bb$ur.lat - bb$ll.lat)))
   
   
   
   
   
   sbar$distance <- geosphere::distVincentyEllipsoid(c(sbar$lon.start,sbar$lat.start),
                                                     c(sbar$lon.end,sbar$lat.end))
   scalebar.length <- 20
   sbar$lon.end <- sbar$lon.start +
      ((sbar$lon.end-sbar$lon.start)/sbar$distance)*scalebar.length*1000
   ptspermm <- 2.83464567  # need this because geom_text uses mm, and themes use pts. Urgh.
   
   map.scale <- ggmap(map.base,
                      extent = "normal", 
                      maprange = FALSE) %+% sites.data +
      geom_point(aes(x = lon,
                     y = lat,
                     colour = colour)) +
      geom_text(aes(x = lon,
                    y = lat,
                    label = label),
                hjust = 0,
                vjust = 0.5,
                size = 8/ptspermm) +    
      geom_segment(data = sbar,
                   aes(x = lon.start,
                       xend = lon.end,
                       y = lat.start,
                       yend = lat.end),
                   arrow=arrow(angle = 90, length = unit(0.1, "cm"),
                               ends = "both", type = "open")) +
      geom_text(data = sbar,
                aes(x = (lon.start + lon.end)/2,
                    y = lat.start + 0.025*(bb$ur.lat - bb$ll.lat),
                    label = paste(format(scalebar.length),
                                  'km')),
                hjust = 0.5,
                vjust = 0,
                size = 8/ptspermm)  +
      coord_map(projection = "mercator",
                xlim=c(bb$ll.lon, bb$ur.lon),
                ylim=c(bb$ll.lat, bb$ur.lat))  
   
   
    mapscale <- list(    #  geom_text(aes(x = lon,
   #                                      y = lat,
   #                                      label = label),
   #                                  hjust = 0,
   #                                  vjust = 0.5,
   #                                  size = 8/ptspermm),    
                             geom_segment(data = sbar,
                                          aes(x = lon.start,
                                              xend = lon.end,
                                              y = lat.start,
                                              yend = lat.end),
                                          arrow=arrow(angle = 90, length = unit(0.1, "cm"),
                                                      ends = "both", type = "open")),
                             geom_text(data = sbar,
                                       aes(x = (lon.start + lon.end)/2,
                                           y = lat.start + 0.025*(bb$ur.lat - bb$ll.lat),
                                           label = paste(format(scalebar.length),
                                                         'km'))
                             )
                          
                          
                          
                          
   )
   
   
   #map.scale
   
   # then do ggmap .... + map.scale + ...
}