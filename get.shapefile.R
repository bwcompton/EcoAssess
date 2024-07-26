'get.shapefile' <- function(shapefile) {
   
   # get.shapefile
   # Process uploaded shapefile
   # Arguments:
   #     shapefile      uploaded shapefile (or .zip containing shapefile)
   # Result:
   #     processed sf polygon
   # B. Compton, 7 May 2024
   
   
   
   if(is.null(shapefile))
      stop('No shapefile')
   
   
   previouswd <- getwd()
   setwd(uploaddir <- dirname(shapefile$datapath[1]))
   on.exit(setwd(previouswd))
   
   for(i in 1:nrow(shapefile))
      file.rename(shapefile$datapath[i], shapefile$name[i])
   
   if(shapefile$type[1] == 'application/x-zip-compressed') {         # If it's a zipped file,
      names <- unzip(paste0(dirname(shapefile$datapath[1]), '/', shapefile$name), overwrite = TRUE)
      shapefile <- data.frame(name = substring(names, 3))
   }
   
   dsn <- paste(uploaddir, shapefile$name[grep(pattern="*.shp$", shapefile$name)], sep="/")
   
   poly <- suppressWarnings(st_read(dsn, quiet = TRUE)) |>
      st_buffer(0.5) |>             # buffer 0.5 m to remove slivers
      st_union()                    # and dissolve
   
   st_transform(poly, '+proj=longlat +datum=WGS84')
}