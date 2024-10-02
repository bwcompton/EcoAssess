'interpolate.size' <- function(area, quantiles) {
   
   # interpolate size of target area between two nearest quantile sizes
   # Arguments:
   #     area        area of target polygon (acres)
   #     quantiles   quantile data (we just need dimnames of sizes)
   # Result (2 element list):
   #     index       vector of 2 indices into quantiles
   #     factor      vector of 2 interpolation factors for indices
   # Interpolate like this: 
   #     sum(q[index] * factor)
   # 
   # Note: I compared percentiles to see whether scaling is closer to linear or logarithmic. It's definitely linear.
   # 
   # B. Compton, 2 Oct 2024
   
   
   
   'resc' <- function(x, a, b)                              # range rescale linearly
      (x - a) / (b - a)
   
   #   'log.resc' <- function(x, a, b)                          # range rescale on log scale (not used)
   #      resc(log10(x), log10(a), log10(b))
   
   
   a <- as.numeric(dimnames(quantiles$full)$acres)          # block sizes we have quantiles for
   i <- pmin(pmax(1, c(sum(a <= area), sum(a < area) + 1)), length(a))
   if(i[1] != i[2])
      f <- 1 - resc(area, a[i[1]], a[i[2]])                 # factor
   else 
      f <- 1                                                # factor in the unlikely event we're outside the range of sampled areas
   
   z <- list(index = i, factor = c(f, 1 - f))
   #   print((c(area, sum(a[z$index] * z$factor))))
   z
}
