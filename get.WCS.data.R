'get.WCS.data' <- function(layer.info, bbox) {
   
   # get.WCS.data
   # Download several layers on WCS server
   # Arguments:
   #     layer.info     list of layer info from get.WCS.info
   #     bbox            bounding bbox
   # Result:
   #     list of layer terra objects
   # B. Compton, 23 Apr 2024
   
   
   cat('\n\n------------getting data within future call--------------\n')
   cat('\nFuture PID = ', Sys.getpid(), '\n')
   
   bbox <- OWSUtils$toBBOX(bbox$xmin, bbox$xmax, bbox$ymin, bbox$ymax)
   layers <- names(layer.info)
   z <- list()
   
   for(i in 1:length(layers)) 
   {
      cat('\n\n--- getting layer ',layers[i], '...')
      t <- Sys.time()
      z[[layers[i]]] <- layer.info[[i]]$getCoverage(bbox = bbox)
      cat(Sys.time() - t, 'sec\n', sep = '')
   }
   cat('\n\n------------done with future call--------------\n')
   
   z[['pid']] <- paste0('\nFuture PID = ', Sys.getpid(), '\n')
   
   z  
}