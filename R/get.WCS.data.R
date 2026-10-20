'get.WCS.data' <- function(server, workspace, layers, bbox) {
   
   # get.WCS.data - quick version
   # Download several layers on WCS server
   # Arguments:
   #     server         server path
   #     workspace      list of workspaces
   #     layers         list of layers
   #     bbox           bounding bbox in OWS format
   # Result:
   #     list of layer terra objects
   # B. Compton, 23 Apr 2024
   
   
   
   url <- '{server}{workspace}/ows/wcs?request=GetCoverage&service=WCS&version=2.0.1&coverageid={layer}&subset=X({xmin},{xmax})&subset=Y({ymin},{ymax})'
   url <- sub('\\{server\\}', server, url)                      # insert server and bounding box
   url <- sub('\\{xmin\\}', bbox$xmin, url)
   url <- sub('\\{xmax\\}', bbox$xmax, url)
   url <- sub('\\{ymin\\}', bbox$ymin, url)
   url <- sub('\\{ymax\\}', bbox$ymax, url)
   
   z <- list()
   
   for(i in 1:length(layers)) 
   {
      url2 <- sub('\\{workspace\\}', workspace[[i]], url)       # now insert workspace and layer name
      url2 <- sub('\\{layer\\}', layers[[i]], url2)                  
      download.file(url2, z[[i]] <- file.path(paste(tempfile(), '_', layers[[i]], '.tif', sep = '')), mode = 'wb', quiet = TRUE)
   }
   names(z) <- layers                                           # keep the names - we'll want them in layer.stats
   z
}
