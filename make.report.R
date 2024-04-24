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
   
   
   
   plot(data[[1]])
   lines(poly)
   # dim(as.array(x))
   # as.array(x)
   print(as.vector(st_area(poly)) * 247.105e-6)
   modalHelp(mean(as.array(data[[1]]), na.rm = TRUE), 'Mean forest ecoConnect')
   
   
}