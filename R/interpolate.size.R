'interpolate.size' <- function(area, acres) {
   
   # interpolate size of target area between two nearest quantile sizes
   # Arguments:
   #     area        area of target polygon (acres)
   #     acres       vector of acres from quantile data
   # Result (2 element list):
   #     index       vector of 2 indices into quantiles
   #     factor      vector of 2 interpolation factors for indices
   # Interpolate like this: 
   #     sum(q[index] * factor)
   # 
   # Note: I compared percentiles to see whether scaling is closer to linear or logarithmic. It's definitely linear.
   # 
   # B. Compton, 2 Oct 2024
   
   
   
   'resc' <- function(x, acres, b)                             # range rescale linearly
      (x - acres) / (b - acres)
   
   i <- pmin(pmax(1, c(sum(acres <= area), sum(acres < area) + 1)), length(acres))
   if(i[1] != i[2])
      f <- 1 - resc(area, acres[i[1]], acres[i[2]])            # factor
   else 
      f <- 1                                                   # factor in the unlikely event we're outside the range of sampled areas
   
   z <- list(index = i, factor = c(f, 1 - f))
   # print((c(area, sum(acres[z$index] * z$factor))))
   z
}
