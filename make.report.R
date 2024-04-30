'make.report' <- function(poly, layer.data, proj.name, proj.info) {
   
   # make.report
   # Produce PDF report for target area
   # Arguments:
   #     poly        user's target area as sf polygon
   #     data        list of terra objects for target area
   #     proj.name   user's project name
   #     proj.info   user's project info
   # Result:
   #     PDF report
   # B. Compton, 24 Apr 2024
   
   
   
   source = 'report_template.Rmd'         # markdown template
   result = 'fancy_report.pdf'            # result filename
   
   downloadHandler(file = result, content = function(result) {
      
      removeModal()
      id <- showNotification('Generating report...', duration = NULL, closeButton = FALSE)
      
      
      acres <- as.vector(st_area(poly)) * 247.105e-6
      fo_mean <- mean(as.array(layer.data[[1]]), na.rm = TRUE)
      wet_mean <- mean(as.array(layer.data[[2]]), na.rm = TRUE)
      params <- list(acres = acres, fo_mean = fo_mean, wet_mean = wet_mean)         # Set up parameters to pass to Rmd document
      
      
      tempReport <- file.path(tempdir(), source)                                    # copy to temp directory so it'll work on the server
      file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
      
      rmarkdown::render(tempReport, output_file = result,                           # knit in child environment
                        params = params,
                        envir = new.env(parent = globalenv()))
      removeNotification(id)
   })
}