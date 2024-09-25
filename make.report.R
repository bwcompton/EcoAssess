'make.report' <- function(layer.data, resultfile, layers, poly, poly.proj, proj.name, proj.info, quantiles) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     layer.data        paths to geoTIFFs of data layers
   #     resultfile        resultfile filename
   #     layers            data frame with 
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
   
   
   
   xxx <- list(layer.data = layer.data, resultfile = resultfile, layers = layers, poly = poly, poly.proj = poly.proj, proj.name = proj.name, proj.info = proj.info)
   saveRDS(xxx, 'c:/temp/make.report.data.RDS')
   # x <- readRDS('c:/temp/make.report.data.RDS'); layer.data <- x$layer.data
   
   #  cat('*** PID ', Sys.getpid(), ' is writing the report in the future [inside make.report]...\n', sep = '')
   
   
   
   source = 'report_template.Rmd'         # markdown template
   t <- Sys.time()


   stats <- layer.stats(lapply(layer.data, rast))
 
   IEI <- format.stats(stats, 'iei', 'mean')
   IEIq <- format.stats(stats, 'iei', 'best')
   connect <- format.stats(stats, 'connect', 'mean', quantiles)
   connectq <- format.stats(stats, 'connect', 'best', quantiles)
   
   table <- data.frame(IEI.levels = layers$pretty.names[layers$which == 'iei'],
                       IEI = IEI, IEIq = IEIq,
                       connect.levels = layers$pretty.names[layers$which == 'connect'],
                       connect = connect, connectq = connectq)
   
   acres <- sum(as.vector(st_area(poly)) * 247.105e-6) 
   acres <- format(round(acres, 1), big.mark = ',')
   date <- sub(' 0', ' ', format(Sys.Date(), '%B %d, %Y'))
   # session$userData$bbox <- as.list(st_bbox(poly.proj))                                   ************ what was this for? ugg
   
   cat('Time taken to do the math: ', Sys.time() - t, '\n')
   
   
   t1 <- Sys.time()
   left <- make.report.maps(poly, 1.5, minsize = 2000)
   cat('Time taken to make left map: ', Sys.time() - t1, '\n')
   t1 <- Sys.time()
   right <- make.report.maps(poly, 5, minsize = 60000)
   cat('Time taken to make right map: ', Sys.time() - t1, '\n')
   
   
   params <- c(proj.name = proj.name, proj.info = proj.info, acres = acres, date = date, path = getwd(), bold = 1, 
               table = table, left = left, right = right)
   
   
   t1 <- Sys.time()
   
   tempReport <- file.path(tempdir(), source)                                    # copy to temp directory so it'll work on the server
   file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
   
   z <- rmarkdown::render(tempReport, output_file = resultfile,                      # knit in child environment
                          params = params,
                          envir = new.env(parent = globalenv()),
                          quiet = TRUE)
   
   cat('Time taken to do knit report: ', Sys.time() - t1, '\n')
   cat('** Time taken for make.report: ', Sys.time() - t, '\n')
   
   z
}
