'make.report' <- function(layers, result, poly, proj.name, proj.info, acres) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     data        list of terra objects for target area
   #     proj.name   user's project name
   #     proj.info   user's project info
   #     acres       area of polygon in acres, before projection messes it up
   # Result:
   #     PDF report
   # B. Compton, 24 Apr 2024
   
   
   
   source = 'report_template.Rmd'         # markdown template
#   result = 'fancy_report.pdf'            # result filename
   
  # downloadHandler(file = result, content = function(result) {
      
      cat('\n\nGenerating PDF...\n\n')
      t <- Sys.time()
      
      argsxxx <<- list(data = data, result = result, poly = poly, proj.name = proj.name, proj.info = proj.info, acres = acres)
 #     stop()
      
 #     print(wrapped.data)
     # data <- lapply(wrapped.data, unwrap)
  #    print(data)
      
      # cat('Result = ', result, '\n')
      # cat('Data = ')
      # cat('project name = ', proj.name, '\n')
      # cat('project info = ', proj.info, '\n')
      # cat('acres = ', acres, '\n\n')
      # cat('data with ', length(data), ' elements\n', sep = '')
      # print(data[[1]])
      # 
      # plot(data[[1]])
      # lines(poly)
      # 
      # 
      
      yyyy <<- layers
      layer.data <- lapply(layers, rast)
      xxxx <<- layer.data
      # plot(layer.data[[1]])
      
      removeModal()
      id <- showNotification('Generating report...', duration = NULL, closeButton = FALSE)
      # 
      # fo_mean <- mean(as.array(layer.data[[1]]), na.rm = TRUE)
      # wet_mean <- mean(as.array(layer.data[[2]]), na.rm = TRUE)
      # params <- list(acres = acres, fo_mean = fo_mean, wet_mean = wet_mean)         # Set up parameters to pass to Rmd document
      
      params <- c(layer.stats(layer.data), acres = acres)
    #  xxx <<- params
      
      tempReport <- file.path(tempdir(), source)                                    # copy to temp directory so it'll work on the server
      file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
      
      z <- rmarkdown::render(tempReport, output_file = result,                           # knit in child environment
                        params = params,
                        envir = new.env(parent = globalenv()))
      removeNotification(id)
      cat(Sys.time() - t, 'sec\n', sep = '')
      
      z
   #})
}