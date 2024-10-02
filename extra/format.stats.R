'format.stats' <- function(stats, which, type, quantiles = NULL, statehuc = NULL, area = NULL) {
   
   # Format stats for make.report
   # Arguments:
   #     stats       statistics data frame, from layer.stats
   #     which       metric either 'iei' or 'connect'
   #     type        statistic type, either 'mean' or 'best' (for mean of top quartile)
   #     quantiles   list of sampled percentiles for full, state, and huc. (connect only)
   #                 Each has 5 dimensions:
   #                    1. region (1 for full, 14 for state, and 245 for huc)
   #                    2. block size (1, 10, ... 1e6 acres)
   #                    3. system
   #                    4. all or best
   #                    5. percentile
   #     statehuc    list of state id, huc id, formatted state name(s), formatted HUC id(s) (connect only)
   #     area        area of target conservation area (acres)
   # B. Compton, 15 Jul 2024 (from make.report)
   
   
   stats <<-stats; xxwhich <<- which; type <<- type; quantiles <<- quantiles; statehuc <<- statehuc
  # return()
   
   

   x <- stats[layers$which == which, type]


   
   cat(which, type, x, '\n')
   
   
   if(which == 'iei') {                                                 # IEI is x.xx (divided by 100), with calculated percentiles
      pctile <- round(x, 0)
      x <- round(x / 100, 2)                                            # percentile from 0-100; zeros will be dropped in formatting
   }
   else {                                                               # connect is xx, with looked-up percentiles
      pctile <- colSums(matrix(x, 100, length(x), byrow = TRUE) >= rbind(0, quantiles[-100,]))
      x <- round(x, 1)
   }
   
   z <- paste0(ifelse(pctile >= 91, '**', ''),
               gsub(' ', '', format(x, nsmall = (which == 'iei') + 1, justify = 'none')),                # IEI is formatted as x.xx, ecoConnect as xx.x
               ifelse(x > 0, 
                      ifelse(pctile >= 51, paste0(' (top ', 101 - pctile, '%)'), 
                             paste0(' (bottom ', pctile, '%)')),
                      ''), 
               ifelse(pctile >= 91, '**', ''))
   z
}