'layer.stats' <- function(layer.data) {
   
   # layer.stats
   # Get stats from ecoConnect and IEI data
   # Arguments:
   #     layer.data      layer data from get.WCS.data
   # Result:
   #     list of stats
   # B. Compton, 9 May 2024
   
   
   
   z <- lapply(layer.data, function(x) mean(as.array(x), na.rm = TRUE))
   z <- lapply(z, function(x) ifelse(is.nan(x), 0, x))
   z <- lapply(z, round, 1)
}