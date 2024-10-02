'format.stats.connect' <- function(stats, type, quantiles, statehuc, size.factors) {
   
   # Format ecoConnect stats for make.report
   # Arguments:
   #     stats       statistics data frame, from layer.stats
   #     type        statistic type, either 'mean' or 'best' (for mean of top quartile)
   #     quantiles   list of sampled percentiles for full, state, and huc. (connect only)
   #                 Each has 5 dimensions:
   #                    1. region (1 for full, 14 for state, and 245 for huc)
   #                    2. block size (1, 10, ... 1e6 acres)
   #                    3. system
   #                    4. all or best
   #                    5. percentile
   #     statehuc    list of state id, huc id, formatted state name(s), formatted HUC id(s) (connect only)
   #     size.factors   indices and blend of block sizes to interpolate target area size
   # B. Compton, 2 Oct 2024 (from format.stats)
   
   
   stats <<-stats; type <<- type; quantiles <<- quantiles; statehuc <<- statehuc; size.factors <<- size.factors
   return()
   
   
   
   x <- stats[layers$which == 'connect', type]
   
   cat('ecoConnect', type, x, '\n')
   
   
   
   pctile <- colSums(matrix(x, 100, length(x), byrow = TRUE) >= rbind(0, quantiles[-100,]))        # connect is xx.x, with looked-up percentiles

   
   
   x <- round(x, 0)                                                                                # report ecoConnect as 2 digits, xx
   z <- paste0(ifelse(pctile >= 91, '**', ''),
               gsub(' ', '', format(x, nsmall = 0, justify = 'none')),                             # ecoConnect as xx
               ifelse(x > 0, 
                      ifelse(pctile >= 51, paste0(' (top ', 101 - pctile, '%)'), 
                             paste0(' (bottom ', pctile, '%)')),
                      ''), 
               ifelse(pctile >= 91, '**', ''))
   z
}