'format.stats.iei' <- function(x, type) {
   
   # Format one row of IEI stats for make.report
   # Arguments:
   #     x           row of statistics data frame, from layer.stats
   #     type        statistic type, either 'all' or 'best'
   # B. Compton, 2 Oct 2024 (from format.stats)
   

   
   pctile <- round(x, 0)                                                            # IEI is x.xx (divided by 100), with calculated percentiles
   x <- round(x / 100, 2)                                                           # percentile from 0-100; zeros will be dropped in formatting
   
   z <- c(type, 
          paste0(ifelse(pctile >= 91, '**', ''),
                 gsub(' ', '', format(x, nsmall = 2, justify = 'none')),            # IEI is formatted as x.xx
                 ifelse(x > 0, 
                        ifelse(pctile >= 51, paste0(' (top ', 101 - pctile, '%)'), 
                               paste0(' (bottom ', pctile, '%)')),
                        ''), 
                 ifelse(pctile >= 91, '**', '')))
   z
}