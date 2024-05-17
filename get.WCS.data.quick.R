'get.WCS.data.quick' <- function(server, layers, bbox) {
   
   # get.WCS.data - quick version
   # Download several layers on WCS server
   # Arguments:
   #     layer.info     list of layer info from get.WCS.info
   #     bbox           bounding bbox in OWS format
   # Result:
   #     list of layer terra objects
   # B. Compton, 23 Apr 2024
   
   
   
   # xxxbbox <<- bbox
   # 
   # print('here we are in get.WCS.data.quick')
   #  print(server)
   #  print(layers)
   #  print(bbox)
   
   url <- '{server}/wcs?request=GetCoverage&service=WCS&version=2.0.1&coverageid={layer}&subset=X({xmin},{xmax})&subset=Y({ymin},{ymax})'
   url <- sub('\\{server\\}', server, url)                      # insert server and bounding box
   url <- sub('\\{xmin\\}', bbox$xmin, url)
   url <- sub('\\{xmax\\}', bbox$xmax, url)
   url <- sub('\\{ymin\\}', bbox$ymin, url)
   url <- sub('\\{ymax\\}', bbox$ymax, url)
   
   #print('still here in get.WCS.data.quick')
   
   z <- list()
   
   for(i in 1:length(layers)) 
   {
      # cat('\n\n--- getting layer ',layers[i], '...')
      # t <- Sys.time()
      url2 <- sub('\\{layer\\}', layers[[i]], url)                   # now insert layer name
      # print(url2)
      download.file(url2, z[[i]] <- file.path(tempdir(), paste(layers[[i]], '.tif', sep = '')), mode = 'wb', quiet = TRUE)
      # print(z[[i]])
      # cat('\n', Sys.time() - t, 'sec\n', sep = '')
   }
   #lapply(z, wrap)
   # cat('\n\nStill here\n\n')
   # print(z)
   z
   
}


# x <- rast('https://umassdsl.webgis1.com/geoserver/ecoConnect/ows/wcs?request=GetCoverage&service=WCS&version=2.0.1&coverageid=ecoConnect__Forest_fowet&subset=X(-8050852,-8049779)&subset=Y(5258243,5259130)', vsi = TRUE)

