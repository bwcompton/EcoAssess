'demo.modal' <- function(poly, data, proj.name, info) {
   
   # demo.modal
   # Temporary function to do demo report
   # B. Compton, 25 Apr 2024
   
   
   
   plot(data[[1]])
   lines(poly)
   
   acres <- round(as.vector(sum(st_area(poly))) * 247.105e-6, 2)
   fo.mean <- round(mean(as.array(data[['Forest_fowet']]), na.rm = TRUE), 2)
   wet.mean <- round(mean(as.array(data[['Nonfo_wet']]), na.rm = TRUE), 2)
   ridge.mean <- round(mean(as.array(data[['Ridgetop']]), na.rm = TRUE), 2)
   floodplain.mean <- round(mean(as.array(data[['LR_floodplain_forest']]), na.rm = TRUE), 2)
   x <- HTML(paste0('<b>Project name</b>: ', proj.name,
                    '</br><p><b>Project description</b>: ', info, '</p>',
                    'Total acres: ', acres, '</br>Mean forest ecoConnect = ', fo.mean,
                    '</br>Mean wetland ecoConnect = ', wet.mean,
                    '</br>Mean ridgetop ecoConnect = ', ridge.mean,
                    '</br>Mean floodplain forest ecoConnect = ', floodplain.mean))
   
   modalHelp(x, 'Conservation target report')
}