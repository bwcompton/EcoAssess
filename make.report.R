'make.report' <- function(layer.data, resultfile, layers, poly, proj.name, proj.info, acres, quick, params) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     layer.data        paths to geoTIFFs of data layers
   #     layers            data frame with 
   #        $server.names     names on GeoServer
   #        $pretty.names     display names
   #        $which            'connect' or 'iei'
   #     poly              sf polygon of target area
   #     resultfile        resultfile filename
   #     proj.name         user's project name
   #     proj.info         user's project info
   #     acres             area of polygon in acres, before projection messes it up
   # Source data:
   #     inst/ecoConnect_quantiles.RDS    percentiles of each ecoConnect layer, from ecoconnect.quantiles.R   
   # resultfile:
   #     PDF report
   # B. Compton, 24 Apr 2024
   
   
   
   
   source = 'report_template.Rmd'         # markdown template
   t <- Sys.time()
   id <- showNotification('Generating report...', duration = NULL, closeButton = FALSE)
   cat('\n\nGenerating PDF...\n\n')
   
   if(quick) {
      params <- xxparams
   } else {                                                    # *** for testing: save params for Do it now button
      stats <- layer.stats(lapply(layer.data, rast))
      quantiles <- readRDS('inst/ecoConnect_quantiles.RDS')
 
      IEIs <-  round(unlist(stats[layers$which == 'iei']) / 100, 2)
      IEI.top <- round((1.01 - IEIs) * 100, 0)
      IEI <- paste0(ifelse(IEI.top <= 10, '**', ''), 
                    IEIs, 
                    ifelse(IEIs > 0, 
                           ifelse(IEI.top <= 50, paste0(' (top ', IEI.top, '%)'), 
                                  paste0(' (bottom ', 101 - IEI.top, '%)')),
                           ''),
                    ifelse(IEI.top <= 10, '**', ''))
      
      connects <- c(unlist(stats[layers$which == 'connect']))
      connect.top <- colSums(matrix(connects, 100, length(connects), byrow = TRUE) < quantiles)
      connect <- paste0(ifelse(connect.top <= 10, '**', ''),
                        connects,
                        ifelse(connects > 0, 
                               ifelse(connect.top <= 50, paste0(' (top ', connect.top, '%)'), 
                                      paste0(' (bottom ', 101 - connect.top, '%)')),
                                      ''), 
                        ifelse(connect.top <= 10, '**', ''))
      
      
      table <- data.frame(IEI.levels = layers$pretty.names[layers$which == 'iei'],
                          IEI = IEI,
                          connect.levels = layers$pretty.names[layers$which == 'connect'],
                          connect = connect)
      
      left <- make.report.maps(poly, 1000, 14)
      right <- make.report.maps(poly, 20000, 10)
      
      params <- c(proj.name = proj.name, proj.info = proj.info, acres = format(round(acres, 1), big.mark = ','), 
                  date = sub(' 0', ' ', format(Sys.Date(), '%B %d, %Y')), path = getwd(), bold = 1, table = table, left = left, right = right)
      xxlayers <<- layers; xxresultfile <<- resultfile; xxparams <<- params
   }
   
   
   tempReport <- file.path(tempdir(), source)                                    # copy to temp directory so it'll work on the server
   file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
   
   z <- rmarkdown::render(tempReport, output_file = resultfile,                      # knit in child environment
                          params = params,
                          envir = new.env(parent = globalenv()))
   removeNotification(id)
   z
}