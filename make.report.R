'make.report' <- function(poly, data, proj.name, proj.info) {
   
   # make.report
   # Produce report for target area
   # Arguments:
   #     poly        user's target area as sf polygon
   #     data        list of terra objects for target area
   #     proj.name   user's project name
   #     proj.info   user's project info
   # Result:
   #     PDF report
   # B. Compton, 24 Apr 2024
   
   print('make.report')
   
   
   # plot(data[[1]])
   # lines(poly)
   # # dim(as.array(x))
   # # as.array(x)
   # print(as.vector(st_area(poly)) * 247.105e-6)
   # modalHelp(mean(as.array(data[[1]]), na.rm = TRUE), 'Mean forest ecoConnect')
   
   
   acres <- as.vector(st_area(poly)) * 247.105e-6
   fo_mean <- mean(as.array(data[[1]]), na.rm = TRUE)
   wet_mean <- mean(as.array(data[[2]]), na.rm = TRUE)
   
   
   
   source = 'report.Rmd'        # markdown template
   result = 'fancy_report.pdf'        # result filename

   print('trying now...')
   #   output$report <- downloadHandler(
      
  # z <- downloadHandler(
   z <- list(   file = result,   
      content = function(result) {
         
         tempReport <- file.path(tempdir(), source)   # copy to temp directory so it'll work on the server
         file.copy(source, tempReport, overwrite = TRUE)
         
         params <- list(acres = acres, fo_mean = fo_mean, wet_mean = wet_mean
         )                   # Set up parameters to pass to Rmd document
         rmarkdown::render(tempReport, output_file = result,  # knit in child environment
                           params = params,
                           envir = new.env(parent = globalenv()))
      }
   )
   print('report produced')
   print(length(z))
   z
}