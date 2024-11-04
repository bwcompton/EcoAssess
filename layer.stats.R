'layer.stats' <- function(grid, statehuc, area, best.prob = 0.75) {
   
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
   
   
   # plot(grid)
   # Sys.sleep(1)
   # return(1)
   
   #xxgrid <<- grid;return()
   
   'best.mean' <- function(x) mean(x[x > quantile(x, prob = best.prob, na.rm = TRUE)], na.rm = TRUE)       # mean of "best", either top quartile or top half
   
   z <- data.frame(all = unlist(lapply(grid, function(y) mean(as.array(y), na.rm = TRUE))),
                   best = unlist(lapply(grid, function(y) best.mean(as.array(y)))))
   
   z[is.na(z)] <- 0         # NaN to 0
   z
}
