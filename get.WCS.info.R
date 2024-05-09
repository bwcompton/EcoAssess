'get.WCS.info' <- function(WCSserver, workspace, layers, log = NULL) {
   
   # get.WCS.info
   # Get capabilities of several layers on WCS server
   # Arguments:
   #     WCSserver      url of WCS server
   #     workspace      name of workspace on server
   #     layers         vector of layer names
   #     log            logging type. Use 'INFO' for development, and NULL for production
   # Result:
   #     list of layer capabilities
   # B. Compton, 23 Apr 2024
   
   
   
   t <- Sys.time()
   
   caps <- WCSClient$new(WCSserver, '2.0.1', logger = log)$getCapabilities()
   z <- list()
   
   
   for(i in layers)
      z[[i]] <- caps$findCoverageSummaryById(paste0(workspace, '__', i), exact = TRUE)
   
   cat(Sys.time() - t, 'sec\n', sep = '')
   
   z
}