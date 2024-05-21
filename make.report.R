'make.report' <- function(layers, result, proj.name, proj.info, acres) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     layers      paths to geoTIFFs of data layers
   #     result      result filename
   #     proj.name   user's project name
   #     proj.info   user's project info
   #     acres       area of polygon in acres, before projection messes it up
   # Result:
   #     PDF report
   # B. Compton, 24 Apr 2024
   
   
   
   source = 'report_template.Rmd'         # markdown template
   
   removeModal()      
   cat('\n\nGenerating PDF...\n\n')
   t <- Sys.time()
   layer.data <- lapply(layers, rast)
   # plot(layer.data[[1]])                  # for testing
   
   
   id <- showNotification('Generating report...', duration = NULL, closeButton = FALSE)
   
   params <- c(layer.stats(layer.data), acres = acres)
   tempReport <- file.path(tempdir(), source)                                    # copy to temp directory so it'll work on the server
   file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
   
   z <- rmarkdown::render(tempReport, output_file = result,                      # knit in child environment
                          params = params,
                          envir = new.env(parent = globalenv()))
   removeNotification(id)


   cat('Time to create report: ', round(Sys.time() - t, 2), ' sec', sep = '')
   
   z
}