'make.report' <- function(layer.data, resultfile, layers, layer.names, proj.name, proj.info, acres, quick, params) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     layer.data        paths to geoTIFFs of data layers
   #     layers            names of layers on GeoServer
   #     layer.names       friendly names of layers for report
   #     resultfile        resultfile filename
   #     proj.name         user's project name
   #     proj.info         user's project info
   #     acres             area of polygon in acres, before projection messes it up
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
      params <- c(layer.stats(lapply(layer.data, rast)), proj.name = proj.name, proj.info = proj.info, acres = round(acres, 1), 
                  date = format(Sys.Date(), '%B %d, %Y'))
      xxlayers <<- layers; xxlayer.names <<- layer.names; xxresultfile <<- resultfile; xxparams <<- params
   }

   
   tempReport <- file.path(tempdir(), source)                                    # copy to temp directory so it'll work on the server
   file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
   
   z <- rmarkdown::render(tempReport, output_file = resultfile,                      # knit in child environment
                          params = params,
                          envir = new.env(parent = globalenv()))
   removeNotification(id)
   z
}