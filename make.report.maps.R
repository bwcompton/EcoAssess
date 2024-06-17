'make.report.maps' <- function(poly, expand, zoom, minsize = 1000) {
   
   # make.report.maps
   # Produce locus maps for report
   # Arguments:
   #     poly        the target area polygon
   #     expand      multiple of poly to expand by (1 = fit to pane). Use 1 for left, 10 for right
   #     minsize     minimum extent of the map, in m
   # result:
   #     name of temporary .png file with map
   # Note: Stadia needs to be registered with the API key. This is done in the calling function with 
   #     register_stadiamaps(readChar(f <- 'www/stadia_api.txt', file.info(f)$size))
   # A free Stadia account allows 200,000 "credits," which I think is generous; if we need more, we'll 
   # have to pay $20/mo or more. Check usage here: https://client.stadiamaps.com/dashboard/#/overview
   # Make sure the API key file is .gitignored!
   # I've hard-coded the Stamen map type, the map size, and dpi. I don't see a need to change these.
   # B. Compton, 10 Jun 2024
   
   

  # zoom <- 11              #### have to figure this out
   
   
   bb <- st_bbox(poly)     # bbox in degrees 
   w <- geosphere::distVincentyEllipsoid(c(bb$xmin, bb$ymin), c(bb$xmax, bb$ymin))          # dimensions in m (within 3% of what I get from ArcGIS; good enough for our purposes)
   h <- geosphere::distVincentyEllipsoid(c(bb$xmin, bb$ymin), c(bb$xmin, bb$ymax))
   exp <- ((s <- expand *  max(w, h, minsize)) / c(w, h)) - 1                                          # multiply bbox dimensions by this to get a square with poly taking 1/expand of the frame
   cat('size = ', s, '\n', sep = '')
   
   range <- c(bb$xmax - bb$xmin, bb$ymax - bb$ymin)                              # dimensions in degrees
   f <- range * exp / 2                                                         # degrees to expand by in each dimension
   
   newbb <- c(bb$xmin - f[1], bb$ymin - f[2], bb$xmax + f[1], bb$ymax + f[2])    # new square expanded bounding box
   newbb <- setNames(newbb, c('left', 'bottom', 'right', 'top'))                 # bounding box with names that get_stadiamap likes
   basemap <- get_stadiamap(bbox = newbb, maptype = 'stamen_toner_lite', zoom = zoom, messaging = FALSE)      # get the basemap
   
   map <- ggmap(basemap) +                                                              # plot the basemap with the poly
      geom_sf(data = poly, aes(), color = 'orange', lwd = 2,fill = NA, inherit.aes = FALSE) +
      theme_void() +
      theme(panel.border = element_rect(color = "black", fill = NA))
   
   
   
   
   return(map)
   
   
   
   
   
   png(file <- file.path(paste(tempfile(), '.png', sep = '')), width = 3.2, height = 3.2, units = 'in', res = 300)
   print(map)                                                                           # to a .png
   dev.off()
   
   file <- gsub('\\\\', '/', file)
   
   file                                                                                 # return the filename
}