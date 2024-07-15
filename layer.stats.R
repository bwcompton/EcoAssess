'layer.stats' <- function(layer.data) {
   
   # layer.stats
   # Get stats from ecoConnect and IEI data
   # Arguments:
   #     layer.data      layer data from get.WCS.data
   # Result:
   #     data frame of stats corresponding to elements of layer.data, with columns mean and qmean (mean of top quartile)
   # B. Compton, 9 May 2024
   
   
   
   'quartile.mean' <- function(x) mean(x[x > quantile(x, prob = 0.75, na.rm = TRUE)], na.rm = TRUE)       # mean of top quartile
   
   z <- data.frame(mean = unlist(lapply(layer.data, function(y) mean(as.array(y), na.rm = TRUE))),
                   qmean = unlist(lapply(layer.data, function(y) quartile.mean(as.array(y)))))
   
   z[is.na(z)] <- 0         # NaN to 0
   z
}
