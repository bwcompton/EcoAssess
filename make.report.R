'make.report' <- function(input, output, session) {
   
   # make.report
   # Produce report for target area
   # Arguments:
   #     poly        user's target area as sf polygon
   #     data        list of terra objects for target area
   #     session$userData$proj.name   user's project name
   #     session$userData$proj.info   user's project info
   # Result:
   #     PDF report
   # B. Compton, 24 Apr 2024
   
   
   
   source = 'report_template.Rmd'        # markdown template
   result = 'fancy_report.pdf'        # result filename
   
   downloadHandler(
      file = result,   
      content = function(result) {
         
         session$userData$session$userData$proj.name <- input$proj.name   # save these from OK
         session$userData$session$userData$proj.info <- input$proj.info
         removeModal()
         
         acres <- as.vector(st_area(session$userData$poly)) * 247.105e-6
         fo_mean <- mean(as.array(session$userData$layer.data[[1]]), na.rm = TRUE)
         wet_mean <- mean(as.array(session$userData$layer.data[[2]]), na.rm = TRUE)
         
         
         tempReport <- file.path(tempdir(), source)   # copy to temp directory so it'll work on the server
         cat('\n\n*** Copying from ', source, ', to ', tempReport, '\n', sep = '')
         cat('\n*** Final result will be in ', result, '\n', sep = '')
         
         file.copy(paste0('inst/', source), tempReport, overwrite = TRUE)
         
         params <- list(acres = acres, fo_mean = fo_mean, wet_mean = wet_mean)          # Set up parameters to pass to Rmd document
         
         cat('\n*** Producing report ', result, '\n')
         
         rmarkdown::render(tempReport, output_file = result,  # knit in child environment
                           params = params,
                           envir = new.env(parent = globalenv()))
      }
   )
}
