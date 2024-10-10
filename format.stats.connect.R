'format.stats.connect' <- function(x, system, type, quantiles, statehuc, size.factors) {
   
   # Format one row of ecoConnect stats for make.report
   # Arguments:
   #     x           statistics data frame, from layer.stats
   #     system      name of system
   #     type        statistic type, either 'mean' or 'best' (for mean of top quartile)
   #     quantiles   list of sampled percentiles for full, state, and huc. (connect only)
   #                 Each has 5 dimensions:
   #                    1. region (1 for full, 14 for state, and 245 for huc)
   #                    2. block size (1, 10, ... 1e6 acres)
   #       
   #                    3. system
   #                    4. all or best
   #                    5. percentile
   #     statehuc    list of state id, huc id, formatted state name(s), formatted HUC id(s) (connect only)
   #     size.factors   indices and blend of block sizes to interpolate target area size
   #
   # Note: in ecoConnect.quantiles, I'm sweeping samples from smaller blocks to fill larger blocks with insufficient
   #       samples, so the only way we'll see NA in quantiles is for sliver HUCs with too few samples. In these rare
   #       cases, we'll report blank percentiles.
   #
   # B. Compton, 2-3 Oct 2024 (from format.stats)
   
   
  # x<<-x;system<<-system;type<<-type;quantiles<<-quantiles;statehuc<<-statehuc;size.factors<<-size.factors;return()
   
   
   'fmt.percentile' <- function(x, pctile) {                                                             # give score and percentile, format percentiles in top 10% in boldface
      if(!is.na(pctile) & x > 0) {
         z <- if(pctile >= 51)
            paste0('top ', 101 - pctile, '%') 
         else
            paste0('bottom ', pctile, '%')
         
         if(pctile >= 91)
            paste0('**', z, '**')
         else
            z
      }
      else
         '' 
   }
   
   
   fact <- matrix(size.factors$factor, 2, 100)                                                           # size factors as a conforming matrix
   sys <- tolower(ifelse(system == 'Floodplain forests', 'floodplains', system))                         # 🙄
   q <- list()
   q$full <- sum(x >= c(0, (colSums(quantiles$full[1, size.factors$index, sys, type, ] * fact))[-100]))  # percentiles
   q$state <- sum(x >= c(0, (colSums(quantiles$state[statehuc$state, size.factors$index, sys, type, ] * fact))[-100]))
   q$huc <- sum(x >= c(0, (colSums(quantiles$huc[statehuc$huc, size.factors$index, sys, type, ] * fact))[-100]))
   
   
   x <- round(x, 0)                                                                                      # report ecoConnect as 2 digits, xx
   c(system, type, format(x, nsmall = 0, justify = 'none'), 
     fmt.percentile(x, q$full),
     fmt.percentile(x, q$state),
     fmt.percentile(x, q$huc))
}