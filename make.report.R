'make.report' <- function(layer.data, resultfile, layers, poly, poly.proj, proj.name, proj.info, quantiles, session) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     layer.data        paths to geoTIFFs of data layers
   #     resultfile        resultfile filename
   #     layers            data frame with: 
   #        $server.names     names on GeoServer
   #        $pretty.names     display names
   #        $which            'connect' or 'iei'
   #     poly              sf polygon of target area
   #     poly.proj         and the reprojected target area poly
   #     proj.name         user's project name
   #     proj.info         user's project info
   #     quantiles         percentiles of each ecoConnect layer
   # resultfile:
   #     PDF report
   # B. Compton, 24 Apr 2024
   

   
   #xxx <- list(layer.data = layer.data, resultfile = resultfile, layers = layers, poly = poly, poly.proj = poly.proj, proj.name = proj.name, proj.info = proj.info, quantiles = quantiles)
   #saveRDS(xxx, 'inst/zzz_make.report.data.RDS')
   # x <- readRDS('inst/zzz_make.report.data.RDS'); layer.data <- x$layer.data; resultfile <- x$resultfile; layers <- x$layers; poly <- x$poly; poly.proj <- x$poly.proj; proj.name <- x$proj.name; proj.info <- x$proj.info; quantiles <- x$quantiles
   
   #  cat('*** PID ', Sys.getpid(), ' is writing the report in the future [inside make.report]...\n', sep = '')
   
   
   source = 'report_template.Rmd'                                             # markdown template
   t <- Sys.time()
   
   
   area <- sum(as.vector(st_area(poly)) * 247.105e-6) 
   shindex <- rast(layer.data$shindex)                                        # read the state-huc index/mask
   poly.rast <- rasterize(vect(poly.proj), rast(layer.data$shindex)) * 0 + 1  # raster version of polygon, 1 inside, NA outside
   poly.rast[is.na(shindex)] <- NA                                            # clip poly.rast with shindex to remove subtidal. We'll use this ask the mask in layer.stats
   
   statehuc <- get.statehuc(shindex * poly.rast, quantiles$stateinfo, 
                            quantiles$hucinfo)                                # look up state(s) and HUC(s) from shindex, clipped to poly
   stats <- do.call(rbind.data.frame, lapply(layer.data[-length(layer.data)], function(x) layer.stats(rast(x) * poly.rast, statehuc, area)))
   size.factors <- interpolate.size(area, as.numeric(dimnames(quantiles$full)$acres))
   
   
   IEI <- format.stats.iei(stats$all[layers$which == 'iei'], 'all')          # format 2 IEI rows in stats table
   IEI.best <- format.stats.iei(stats$best[layers$which == 'iei'], 'best') 
   
   connect <- data.frame(matrix(NA, 8, 6))                                    # and 8 ecoConnect rows
   names(connect) <- c('System', 'Type', 'Score', 'Region', 'State', 'Watershed')
   systems <- layers$pretty.names[layers$which == 'connect']
   systems.server <- layers$server.names[layers$which == 'connect']
   type <- c('all', 'best')
   for(i in 1:length(systems))
      for(j in 1:2)
         connect[(i - 1) * 2 + j, ] <- format.stats.connect(stats[systems.server[i], type[j]], systems[i], type[j], quantiles, statehuc, size.factors)

   
   table <- list(IEI.levels = layers$pretty.names[layers$which == 'iei'],
                       IEI = IEI, IEI.best = IEI.best,
                       connect.levels = names(connect),
                       connect1 = connect[1, ], connect2 = connect[2, ], connect3 = connect[3, ], connect4 = connect[4, ],
                       connect5 = connect[5, ], connect6 = connect[6, ], connect7 = connect[7, ], connect8 = connect[8,])
   
   acres <- format(round(area, 1), big.mark = ',')
   date <- sub(' 0', ' ', format(Sys.Date(), '%B %d, %Y'))
   
   cat('Time taken to do the math: ', Sys.time() - t, '\n')
   
   
   t1 <- Sys.time()
   left <- make.report.maps(poly, 1.5, minsize = 2000)
   cat('Time taken to make left map: ', Sys.time() - t1, '\n')
   t1 <- Sys.time()
   right <- make.report.maps(poly, 5, minsize = 60000)
   cat('Time taken to make right map: ', Sys.time() - t1, '\n')
   

   params <- c(proj.name = proj.name, proj.info = proj.info, acres = acres, state = statehuc$state.text, huc = statehuc$huc.text, 
               date = date, path = getwd(), bold = 1, table = table, left = left, right = right)
   
   
   t1 <- Sys.time()
   
   tempReport <- file.path(tempdir(), source)                                 # copy to temp directory so it'll work on the server
   file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
   
   z <- rmarkdown::render(tempReport, output_file = resultfile,               # knit in child environment
                          params = params,
                          envir = new.env(parent = globalenv()),
                          quiet = TRUE)
   
   cat('Time taken to do knit report: ', Sys.time() - t1, '\n')
   cat('** Time taken for make.report: ', Sys.time() - t, '\n')
   
   z
}
