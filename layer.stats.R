'layer.stats' <- function(layers) {
   
   # layer.stats
   # Get stats from ecoConnect and IEI data
   # Arguments:
   #     layers      layer data from get.WCS.data
   # Result:
   #     list of stats
   # B. Compton, 9 May 2024
   
   
   
   fo_mean <- mean(as.array(layers[[1]]), na.rm = TRUE)
   wet_mean <- mean(as.array(layers[[2]]), na.rm = TRUE)
   
   list(fo_mean = fo_mean, wet_mean = wet_mean)
}