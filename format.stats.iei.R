'format.stats.iei' <- function(stats, type) {
   
   # Format IEI stats for make.report
   # Arguments:
   #     stats       statistics data frame, from layer.stats
   #     type        statistic type, either 'mean' or 'best' (for mean of top quartile)
   # B. Compton, 2 Oct 2024 (from format.stats)
   
   
   
   x <- stats[layers$which == 'iei', type]
   
   cat(type, x, '\n')
   
   
   pctile <- round(x, 0)                                                            # IEI is x.xx (divided by 100), with calculated percentiles
   x <- round(x / 100, 2)                                                           # percentile from 0-100; zeros will be dropped in formatting
   
   z <- paste0(ifelse(pctile >= 91, '**', ''),
               gsub(' ', '', format(x, nsmall = 2, justify = 'none')),              # IEI is formatted as x.xx
               ifelse(x > 0, 
                      ifelse(pctile >= 51, paste0(' (top ', 101 - pctile, '%)'), 
                             paste0(' (bottom ', pctile, '%)')),
                      ''), 
               ifelse(pctile >= 91, '**', ''))
   z
}