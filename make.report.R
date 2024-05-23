'make.report' <- function(layers, resultfile, proj.name, proj.info, acres, quick, params) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     layers      paths to geoTIFFs of data layers
   #     resultfile      resultfile filename
   #     proj.name   user's project name
   #     proj.info   user's project info
   #     acres       area of polygon in acres, before projection messes it up
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
      layer.data <- lapply(layers, rast)
      params <- c(layer.stats(layer.data), proj.name = proj.name, proj.info = proj.info, acres = acres)
      xxresultfile <<- resultfile; xxparams <<- params
   }
   
  
   tempReport <- file.path(tempdir(), source)                                    # copy to temp directory so it'll work on the server
   file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
   
   z <- rmarkdown::render(tempReport, output_file = resultfile,                      # knit in child environment
                          params = params,
                          envir = new.env(parent = globalenv()))
   removeNotification(id)
   z
}