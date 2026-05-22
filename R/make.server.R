'make.server' <- function(input, output, session) {

   # make.server
   # The Shiny server function -- one of the two entry points captured by
   # shinyApp() in EcoAssess.app.R. Body is unchanged from the previous
   # inline definition; only the wrapping function name differs so it can
   # live in R/ and be picked up by Shiny's autoloader.
   # B. Compton


   session$userData$cfg <- isolate(resolve.cfg(session$clientData$url_search))   # same cfg the
                                                                                 # UI saw. isolate()
                                                                                 # because url_search
                                                                                 # is a reactive value
                                                                                 # and we want it once.
   cfg <- session$userData$cfg

   if(identical(cfg$layer, 'none')) {                 # decision 7: restore the "layers off"
      session$userData$show.layer <- 'none'           #   state carried across a switch (no
      shinyjs::disable('ecoConnectDisplay')           #   layer radio is set, so no observer
      shinyjs::disable('opacity')                     #   fires to do this)
   }

   shinyjs::disable('restart')
   shinyjs::disable('getReport')
   shinyjs::disable('show.usermap')

   #bs_themer()                                 # uncomment to select a new theme
   #  print(getDefaultReactiveDomain())


   tryCatch({
      if(GET(geoserver$primary)$status_code != 200) stop()                          # ----- Ping our GeoServer
      session$userData$geoserver <- geoserver$primary
      session$userData$using <- 'GeoServer 1'
   },
   error = function(e) {
      message('Primary failed')
      tryCatch({
         if(GET(geoserver$fallback)$status_code != 200) stop()
         session$userData$geoserver <- geoserver$fallback
         session$userData$using <- 'GeoServer 2'
      },
      error = function(e) {                                                         #      if fallback fails too, throw an error
         message('Fallback failed')
         error.message('GeoServer')
         shinyjs::disable('drawPolys')
         shinyjs::disable('uploadShapefile')
      })
   })


   message('Using ', session$userData$geoserver)


   if(!cfg$regional) {                                # ----- Massachusetts mode: parcels
      if(is.null(parcels.layer())) {                  #      endpoint unreachable: degrade
         message('Parcels unavailable')               #      to draw/upload only
         shinyjs::disable('show.parcels')
         shinyjs::disable('selectParcels')
      }
      else
         parcel.server(input, output, session)
   }


   observeEvent(input$aboutTool, {
      modalHelp(aboutTool, 'About this site', size = 'l')})
   observeEvent(input$aboutecoConnect, {
      modalHelp(aboutecoConnect, 'About ecoConnect', size = 'l')})
   observeEvent(input$aboutIEI, {
      modalHelp(aboutIEI, 'About the Index of Ecological Integrity', size = 'l')})
   observeEvent(input$whatsNew, {
      modalHelp(aboutWhatsNew, 'What\'s new in this version?', size = 'l')})


   output$map <- renderLeaflet({                                                    # ----- Draw static parts of Leaflet map
      leaflet('map',
              options = leafletOptions(maxZoom = 16)) |>
         addScaleBar(position = 'bottomleft') |>
         osmGeocoder(position = 'bottomright', email = osm_email) |>
         setView(lng = cfg$view$lng, lat = cfg$view$lat, zoom = cfg$view$zoom)
   })

   observeEvent(input$switch.mode, {                         # ----- switch regional <-> MA
      carry <- list(layer      = session$userData$show.layer,   # decision 7: carry control
                    display    = input$ecoConnectDisplay,       #   state across the switch
                    basemap    = input$show.basemap,
                    opacity    = input$opacity,
                    boundaries = input$show.boundaries)
      if(isTRUE(input$map_zoom > cfg$home.zoom)) {            #   zoomed in past the overview:
         b <- input$map_bounds                               #   also carry the current view
         carry$lng  <- (b$west + b$east) / 2
         carry$lat  <- (b$south + b$north) / 2
         carry$zoom <- input$map_zoom
      }
      shinyjs::runjs(sprintf("window.location.href = '%s';", switch.url(cfg, carry)))
   })

   observeEvent(input$fullscreen,
                js$fullscreen(input$fullscreen), ignoreInit = TRUE)

   observeEvent(input$connect.layer, {
      session$userData$show.layer <- input$connect.layer
      updateRadioButtons(inputId ='iei.layer', selected = character(0))
      enable('ecoConnectDisplay')
      enable('opacity')
   })

   observeEvent(input$iei.layer, {
      session$userData$show.layer <- input$iei.layer
      updateRadioButtons(inputId ='connect.layer', selected = character(0))
      updateCheckboxInput(inputId = 'no.layers', value = 0)
      disable('ecoConnectDisplay')
      enable('opacity')
   })

   observeEvent(input$no.layers, {
      session$userData$show.layer <- 'none'
      updateRadioButtons(inputId ='iei.layer', selected = character(0))
      updateRadioButtons(inputId ='connect.layer', selected = character(0))
      updateCheckboxInput(inputId = 'no.layers', value = 0)
      disable('ecoConnectDisplay')
      disable('opacity')
   })

   observeEvent(list(input$connect.layer, input$iei.layer, input$show.basemap,   # ----- Draw dynamic parts of Leaflet map
                     input$opacity, input$autoscale, input$ecoConnectDisplay, input$show.boundaries,
                     input$show.usermap), {
                        if(length(session$userData$show.layer) != 0 && session$userData$show.layer == 'none')
                           leafletProxy('map') |>
                           addProviderTiles(provider = input$show.basemap, layerId = 'basemap') |>
                           removeTiles(layerId = 'dsl.layers') |>
                           addUserBasemap(input$show.usermap, session$userData$userPoly) |>
                           addBoundaries(input$show.boundaries, session$userData$geoserver)
                        else {
                           if(sub(':.*', '', session$userData$show.layer) == 'ecoConnect')                 # if ecoConnect, use scaled style
                              style <- paste0(sub('.*:', '', session$userData$show.layer),
                                              match(input$ecoConnectDisplay, c('local', 'medium', 'regional')) / 2 + 0.5)
                           else                                                                            # else, use default style for IEI
                              style <- ''

                           leafletProxy('map') |>
                              addProviderTiles(provider = input$show.basemap, layerId = 'basemap') |>
                              addWMSTiles(paste0(session$userData$geoserver, 'wms'), layerId = 'dsl.layers', layers = session$userData$show.layer,
                                          options = WMSTileOptions(opacity = input$opacity / 100, styles = style),
                                          attribution = session$userData$using) |>
                              addUserBasemap(input$show.usermap, session$userData$userPoly) |>
                              addBoundaries(input$show.boundaries, session$userData$geoserver)
                        }
                     })

   observeEvent(input$drawPolys, {                    # ----- Draw button
      shinyjs::disable('drawPolys')
      shinyjs::disable('uploadShapefile')
      shinyjs::enable('restart')

      session$userData$drawn <- TRUE
      proxy <- leafletProxy('map')
      addDrawToolbar(proxy, polygonOptions = drawPolygonOptions(shapeOptions = drawShapeOptions(color = 'purple', weight = 4, fillOpacity = 0)),
                     polylineOptions = FALSE, circleOptions = FALSE, rectangleOptions = FALSE, markerOptions = FALSE,
                     circleMarkerOptions = FALSE, editOptions = editToolbarOptions())
   })

   observeEvent(input$map_draw_all_features, {        # when the first poly is finished, get report becomes available
      if(!is.null(input$map_draw_all_features))
         shinyjs::enable('getReport')
   })

   observeEvent(input$uploadShapefile, {              # ----- Upload button
      # do modal dialog to get shapefile
      showModal(modalDialog(
         title = 'Select shapefile to upload',
         fileInput('shapefile', '', accept = c('.shp', '.shx', '.prj', '.zip'), multiple = TRUE,
                   placeholder = 'must include .shp, .shx, and .prj', width = '100%'),
         footer = tagList(
            modalButton('OK'),
            actionButton('restart', 'Cancel'))
      ))
      shinyjs::disable('getReport')
   })

   observeEvent(input$shapefile, {                    # --- Have uploaded shapefile
      tryCatch({
         session$userData$poly <- get.shapefile(input$shapefile)
         draw.poly(session$userData$poly)
         session$userData$drawn <- FALSE
         shinyjs::disable('drawPolys')
         shinyjs::disable('uploadShapefile')
         shinyjs::enable('getReport')
         shinyjs::enable('restart')
      },
      error = function(e) {
         error.message('Shapefile')
         shinyjs::enable('drawPolys')                 # bad shapefile: do a restart
         shinyjs::enable('uploadShapefile')
         shinyjs::disable('restart')
         shinyjs::disable('getReport')
      })
   })


   observeEvent(input$restart, {                      # ----- Restart button
      shinyjs::enable('drawPolys')
      shinyjs::enable('uploadShapefile')
      shinyjs::disable('restart')
      shinyjs::disable('getReport')
      removeModal()                                   # when triggered by cancel button in upload

      leafletProxy('map') |>
         removeDrawToolbar(clearFeatures = TRUE) |>
         clearGroup(group = 'targetArea')
   })



   observeEvent(input$upload.usermap, {              # ----- Upload map button for user basemap
      # do modal dialog to get shapefile
      showModal(modalDialog(
         title = 'Select shapefile to upload',
         fileInput('user.shapefile', '', accept = c('.shp', '.shx', '.prj', '.zip'), multiple = TRUE,
                   placeholder = 'must include .shp, .shx, and .prj', width = '100%'),
         footer = tagList(
            modalButton('Done'))
      ))
   })

   observeEvent(input$user.shapefile, {               # --- Have uploaded shapefile for user basemap
      tryCatch({
         session$userData$userPoly <- get.shapefile(input$user.shapefile, merge = FALSE)
         leafletProxy('map') |>
            addUserBasemap(FALSE) |>                   # clear old shapefile
            addUserBasemap(TRUE, session$userData$userPoly)
         shinyjs::enable('show.usermap')
         updateCheckboxInput('show.usermap', value = TRUE, session = getDefaultReactiveDomain())
      },
      error = function(e) {
         error.message('Shapefile')
      })
   })



   observeEvent(input$getReport, {                    # ----- Get report button
      output$time <- renderText({
         paste('Wait time ', round(session$userData$time, 2), ' sec', sep = '')
      })


      if(session$userData$drawn)                      #     If drawn polygon,
         session$userData$poly <- geojsonio::geojson_sf(jsonlite::toJSON(input$map_draw_all_features, auto_unbox = TRUE))  #    drawn poly as sf

      session$userData$saved <- list(input$proj.name, input$proj.info)

      sf::sf_use_s2(FALSE)                                                 # need to turn off s2 before fixing shapefiles to avoid crashes on intersections
      session$userData$poly <- sf::st_make_valid(session$userData$poly)    # attempt to fix bad shapefiles
      sf::sf_use_s2(TRUE)

      session$userData$poly.proj <- sf::st_transform(session$userData$poly, 3857) # project to match downloaded rasters
      session$userData$bbox <- as.list(sf::st_bbox(session$userData$poly.proj))

      poly.area <- sum(as.vector(sf::st_area(session$userData$poly)) * 247.105e-6)
      #cat('\n\narea = ', poly.area, ' acres\n', sep = '')

      #sf::st_write(session$userData$poly.proj, 'C:/GIS/GIS/sample_parcels/debug/ab1.shp')
      #sf::st_write(sf::st_buffer(session$userData$poly.proj, -15), 'C:/GIS/GIS/sample_parcels/debug/ab2.shp')


      if(poly.area < 1) {
         error.message('Toosmall')
         return()
      }

      bbarea <- (session$userData$bbox$xmax - session$userData$bbox$xmin) * (session$userData$bbox$ymax - session$userData$bbox$ymin) * 247.105e-6

      if(bbarea > 1e6) {
         error.message('Toobig')
         return()
      }


      # Read template to make sure we're in landscape and we have enough cells
      l <- layers$which == 'template'

      #cat('Trying to read...\n')
      template <- tryCatch({get.WCS.data(session$userData$geoserver, layers$workspaces[l], layers$server.names[l], session$userData$bbox)},
                           warning = function(e) {
                              error.message('ReadFail')
                           })

      if(!is.null(template)) {                           # if we successfully read raster data,
         x <- terra::rast(template$template)
         cells <- sum(as.vector(terra::rasterize(terra::vect(session$userData$poly.proj), x) * x), na.rm = TRUE)          # number of good data cells we've read

         #plot(terra::rasterize(terra::vect(session$userData$poly.proj), x) * x)  ############# temp
         #cat('We read ', cells ,' cells\n', sep = '')              ############# temp


         if(cells < 2)
            error.message('NoCells')

         else {

            showModal(modalDialog(                       # --- Modal input to get project name and description
               textInput('proj.name', 'Project name', value = input$proj.name, width = '100%',
                         placeholder = 'Project name for report'),
               textAreaInput('proj.info', 'Project description', value = input$proj.info,
                             width = '100%', rows = 6, placeholder = 'Optional project description'),
               footer = tagList(
                  show_spinner(),
                  tipped(disabled(downloadButton('do.report', 'Generate report')), generateReportTooltip),
                  actionButton('cancel.report', 'Cancel')
               )
            ))


            # -- Download data while user is typing project info

            xxpoly <<- session$userData$poly
            xxpoly.proj <<- session$userData$poly.proj
            #  sf::st_write(session$userData$poly, 'C:/GIS/GIS/sample_parcels/name.shp')  # save drawn poly as shapefile

            # cat('*** PID ', Sys.getpid(), ' asking to download data in the future...\n', sep = '')
            t <- Sys.time()
            downloading <- showNotification('Downloading data...', duration = NULL, closeButton = FALSE)


            session$userData$the.promise <- future_promise({
               #cat('*** PID ', Sys.getpid(), ' is working in the future...\n', sep = '')
               get.WCS.data(session$userData$geoserver, layers$workspaces, layers$server.names, session$userData$bbox)    # ----- Download data in the future
            }, seed = TRUE)
            then(session$userData$the.promise, onFulfilled = function(x) {
               #   cat('*** The promise has been fulfilled!\n')
               enable('do.report')
               hide_spinner()
               removeNotification(downloading)
            })
            session$userData$time <- Sys.time() - t
            NULL
         }
      }
   })


   observeEvent(input$cancel.report, {                   # --- Cancel button from report dialog. Go back to previous values
      removeModal()
      updateTextInput(inputId = 'proj.name', value = session$userData$saved[[1]])
      updateTextInput(inputId = 'proj.info', value = session$userData$saved[[2]])
   })


   # --- Generate report button from report dialog
   output$do.report <- downloadHandler(
      filename = function() {
         if(input$proj.name == '')     # if no project name, use default report name
            'report.pdf'
         else {                         # else clean up the project name and use it
            gsub('[ <>:"/\\|?*]', '_', input$proj.name) |>
               gsub('[_]+', '_', x = _) |>
               paste0('.pdf')
         }
      },
      content = function(localfile) {
         removeModal()
         session$userData$the.promise %...>%             # when data downloading promise is fulfilled, make the report in the future
            call.make.report(., localfile, layers, session$userData$poly, session$userData$poly.proj,
                             gsub('\\\\', '/', input$proj.name), input$proj.info, session = getDefaultReactiveDomain())
      })
}
