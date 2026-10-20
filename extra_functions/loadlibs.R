'loadlibs' <- function(libraries) {
   
   # Get loading times for all libraries
   # On shinyapps.io, view results in app log
   # Note that posting on shinyapps.io apparently scans library() calls, so they 
   # must be somewhere in app, or the app must be posted as a package
   # B. Compton, 15 Jul 2024
   
   
   
   times <- data.frame(library = libraries, time = NA)
   
   for(i in 1:length(libraries)) {
      a <- Sys.time()
      library(libraries[i], character.only = TRUE)
      times$time[i] <- Sys.time() - a
   }
   
   times$pct <- round(times$time / sum(times$time) * 100, 2)
   times$time <- round(times$time, 2)
   times <- times[order(times$time, decreasing = TRUE), ]
   times$cumpct <- cumsum(times$pct)
   
   print(times)
   cat('Total time to load libraries = ', sum(times$time), ' sec\n', sep = '')
   times <<- times
   
}