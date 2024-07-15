'make.report' <- function(layer.data, resultfile, layers, poly, poly.proj, proj.name, proj.info) {
   
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
   # Source data:
   #     inst/ecoConnect_quantiles.RDS    percentiles of each ecoConnect layer, from ecoconnect.quantiles.R   
   # resultfile:
   #     PDF report
   # B. Compton, 24 Apr 2024
   
   
   
   #  cat('*** PID ', Sys.getpid(), ' is writing the report in the future [inside make.report]...\n', sep = '')
   
   source = 'report_template.Rmd'         # markdown template
   t <- Sys.time()
   
   
   stats <- layer.stats(lapply(layer.data, rast))
   # quantiles <- readRDS('inst/ecoConnect_quantiles.RDS')        # cell-based percentiles
   quantiles <- readRDS('inst/ecoConnect_quantiles_100.RDS')  # percentiles of 100 acre blocks
   
   IEIs <-  round(unlist(stats[layers$which == 'iei']) / 100, 2)
   IEI.top <- round((1.01 - IEIs) * 100, 0)
   IEI <- paste0(ifelse(IEI.top <= 10, '**', ''), 
                 format(IEIs, nsmall = 2), 
                 ifelse(IEIs > 0, 
                        ifelse(IEI.top <= 50, paste0(' (top ', IEI.top, '%)'), 
                               paste0(' (bottom ', 101 - IEI.top, '%)')),
                        ''),
                 ifelse(IEI.top <= 10, '**', ''))
   
   connects <- round((unlist(stats[layers$which == 'connect'])), 0)
   connect.top <- colSums(matrix(connects, 100, length(connects), byrow = TRUE) < quantiles)
   
   connect <- paste0(ifelse(connect.top <= 10 & connects != 0, '**', ''),
                     connects,
                     ifelse(connects > 0, 
                            ifelse(connect.top <= 50, paste0(' (top ', connect.top, '%)'), 
                                   paste0(' (bottom ', 101 - connect.top, '%)')),
                            ''), 
                     ifelse(connect.top <= 10 & connects != 0, '**', ''))
   
   
   table <- data.frame(IEI.levels = layers$pretty.names[layers$which == 'iei'],
                       IEI = IEI,
                       connect.levels = layers$pretty.names[layers$which == 'connect'],
                       connect = connect)
   
   acres <- sum(as.vector(st_area(poly)) * 247.105e-6) 
   acres <- format(round(acres, 1), big.mark = ',')
   date <- sub(' 0', ' ', format(Sys.Date(), '%B %d, %Y'))
   # session$userData$bbox <- as.list(st_bbox(poly.proj))
   
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