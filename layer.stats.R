'layer.stats' <- function(grid, statehuc, area, best.prob = 0.5) {
   
   # layer.stats
   # Get stats from ecoConnect and IEI data
   # Arguments:
   #     grid           raster of layer, clipped to polygon and shindex
   #     statehuc       state and huc numbers
   #     area           area of project area (acres)
   #     best.prob      proportion of target area to take mean of for "best," probably either 0.5 for top 50% or 0.75 for top 25%
   # Result:
   #     data frame of stats corresponding to elements of layer.data, with columns mean and best (mean of top quartile)
   # B. Compton, 9 May 2024
   
   
   plot(grid)
   Sys.sleep(1)
   return(1)
   
   
   'quartile.mean' <- function(x) mean(x[x > quantile(x, prob = best.prob, na.rm = TRUE)], na.rm = TRUE)       # mean of top quartile
   
   z <- data.frame(mean = unlist(lapply(layer.data, function(y) mean(as.array(y), na.rm = TRUE))),
                   best = unlist(lapply(layer.data, function(y) quartile.mean(as.array(y)))))
   
   z[is.na(z)] <- 0         # NaN to 0
   z
}
