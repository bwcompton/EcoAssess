'format.stats' <- function(stats, which, type, quantiles) {
   
   # Format stats for make.report
   # Arguments:
   #     stats       statistics data frame, from layer.stats
   #     which       metric either 'iei' or 'connect'
   #     type        statistic type, either 'mean' or 'best' (for mean of top quartile)
   #     quantiles   quantiles (connect only), read by calling function
   # B. Compton, 15 Jul 2024 (from make.report)
   
   

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