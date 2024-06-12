'make.report.maps' <- function(poly, buffer, zoom) {
   
   # make.report.maps
   # Produce locus maps for report
   # Arguments:
   #     poly        the target area polygon
   #     buffer      buffer in m (use 3000 for left, 30000 for right)
   #     zoom        zoom level (use 13 for left, 10 for right)
   # result:
   #     name of temporary .png file with map
   # Note: Stadia needs to be registered with the API key. This is done in the calling function with 
   #     register_stadiamaps(readChar(f <- 'www/stadia_api.txt', file.info(f)$size))
   # A free Stadia account allows 200,000 "credits," which I think is generous; if we need more, we'll 
   # have to pay $20/mo or more. Check usage here: https://client.stadiamaps.com/dashboard/#/overview
   # Make sure the API key file is .gitignored!
   # I've hard-coded the Stamen map type, the map size, and dpi. I don't see need to change these.
   # B. Compton, 10 Jun 2024
   
   
   
   full <- st_buffer(poly, buffer)                                                      # buffer target area so it doesn't fill the pane
   bb <- setNames(unlist(st_bbox(full)), c('left', 'bottom', 'right', 'top'))           # bounding box
   basemap <- get_stadiamap(bbox = bb, maptype = 'stamen_toner_lite', zoom = zoom, messaging = FALSE)      # get the basemap
   
   map <- ggmap(basemap) +                                                              # plot the basemap with the poly
      geom_sf(data = poly, aes(), color = 'orange', lwd = 2,fill = NA, inherit.aes = FALSE) +
      theme_void() +
      theme(panel.border = element_rect(color = "black", fill = NA))
   
   png(file <- file.path(paste(tempfile(), '.png', sep = '')), width = 3.2, height = 3.2, units = 'in', res = 300)
   print(map)                                                                           # to a .png
   dev.off()
   
   file <- gsub('\\\\', '/', file)
   
   file                                                                                 # return the filename
}