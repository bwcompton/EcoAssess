'get.shapefile' <- function(shapefile) {
   
   # get.shapefile
   # Process uploaded shapefile
   # Arguments:
   #     shapefile      uploaded sf object
   # Result:
   #     processed polygon
   # B. Compton, 7 May 2024
   
   
   
   if(is.null(shapefile)){
      return()
   }
   previouswd <- getwd()
   setwd(uploaddir <- dirname(shapefile$datapath[1]))
   on.exit(setwd(previouswd))
   
   for(i in 1:nrow(shapefile))
      file.rename(shapefile$datapath[i], shapefile$name[i])
   
   dsn <- paste(uploaddir, shapefile$name[grep(pattern="*.shp$", shapefile$name)], sep="/")
   poly <- st_read(dsn) |>
      st_buffer(0.5) |>             # buffer 0.5 m to remove slivers
      st_union()                    # and dissolve
   
   
   qq1 <<- poly
   
   ###### >>>> Trap errors here if the shapefile is bad. We'll check for it being too big later
   
   
   st_transform(poly, '+proj=longlat +datum=WGS84')
}