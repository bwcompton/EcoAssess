'make.report.maps' <- function(poly, expand, minsize = 1000, 
                               zoomfit = c(intercept = 1.412e+01, size = -1.857e-04, size2 = 1.802e-09, max = 60000)) {
   
   # make.report.maps
   # Produce locus maps for report
   # Arguments:
   #     poly        the target area polygon
   #     expand      multiple of long dimension of poly for final map by (1 = fit to pane)
   #     minsize     minimum extent of final map, in m
   #     zoomfit     regression parameters for estimating zoom level from width/height of map pane (in m)
   # result:
   #     name of temporary .png file with map
   # Note: Stadia needs to be registered with the API key. This is done in the calling function with 
   #     register_stadiamaps(readChar(f <- 'www/stadia_api.txt', file.info(f)$size))
   # A free Stadia account allows 200,000 "credits," which I think is generous; if we need more, we'll 
   # have to pay $20/mo or more. Check usage here: https://client.stadiamaps.com/dashboard/#/overview
   # Make sure the API key file is .gitignored!
   # I've hard-coded the Stamen map type, the map size, and dpi. I don't see a need to change these.
   # B. Compton, 10 Jun 2024
   
   
   
   register_stadiamaps(x <- readChar(f <- 'www/stadia_api.txt', file.info(f)$size))       # register Stadia API key

   bb <- st_bbox(poly)                                                                    # bounding box in degrees 
   w <- geosphere::distVincentyEllipsoid(c(bb$xmin, bb$ymin), c(bb$xmax, bb$ymin))        # dimensions in m (within 3% of what I get from ArcGIS; good enough for our purposes)
   h <- geosphere::distVincentyEllipsoid(c(bb$xmin, bb$ymin), c(bb$xmin, bb$ymax))    
   
   range <- c(bb$xmax - bb$xmin, bb$ymax - bb$ymin)                                       # dimensions in degrees
   
   size <- max(max(w, h) * expand, minsize)                                               # final size of the map in m, expanded and at least minsize
   e <- c(h, w) / min(w, h) * max(size / max(w, h), 1)                                    # make the map square and expand it to final size
   f <- (e - 1) * range / 2                                                               # amount to expand lat and long each way in degrees
   
   newbb <- c(bb$xmin - f[1], bb$ymin - f[2], bb$xmax + f[1], bb$ymax + f[2])             # new square expanded bounding box
   newbb <- setNames(newbb, c('left', 'bottom', 'right', 'top'))                          # bounding box with names that get_stadiamap likes
   
   zoom <- floor(zoomfit[1] + zoomfit[2] * min(size, zoomfit[4]) + zoomfit[3] * min(size, zoomfit[4])^2)     # decent zoom from regression on size
   
   # cat('expand = ', expand, ', minsize = ', minsize, '\n', sep = '')
   # cat('*** Original size = ', max(w, h), ' m\n', sep = '')
   # cat('*** Multipliers on dimensions to get final size = ', e[1], ', ', e[2], '\n', sep = '')
   # cat('*** Final size = ', size, ' m\n', sep = '')
   # cat('*** Zoom = ', zoom, '\n', sep ='')
   
   
   basemap <- get_stadiamap(bbox = newbb, maptype = 'stamen_toner_lite', zoom = zoom, messaging = FALSE)     # get the basemap

   
   # print(newbb)
   
   map <- ggmap(basemap) +                                                                # plot the basemap with the poly
      geom_sf(data = poly, aes(), color = 'orange', lwd = 2,fill = NA, inherit.aes = FALSE) +
      theme_void() +
      theme(panel.border = element_rect(color = "black", fill = NA))
   
   
   #################
   
   # return(map)      # for testing with zoomtest.R
   
   #################
   
   
   
   
   png(file <- file.path(paste(tempfile(), '.png', sep = '')), width = 3.2, height = 3.2, units = 'in', res = 300)
   print(map)                                                                           # to a .png
   dev.off()
   
   file <- gsub('\\\\', '/', file)
   
   file                                                                                 # return the filename
}