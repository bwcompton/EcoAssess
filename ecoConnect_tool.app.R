# ecoConnect.tool.app.R - ecoConnect and IEI viewing and reporting tool
# Before initial deployment on shinyapps.io, need to restart R and:
#    library(remotes); install_github('https://github.com/elipousson/sfext.git'); install_github('bwcompton/leaflet.lagniappe')
# YOu'll need to get a Stadia Maps API  key from https://client.stadiamaps.com and save it in www/stadia_api.txt. Make sure 
# to .gitignore this file!

# B. Compton, 19 Apr-17 May 2024



library(shiny)
library(bslib)
library(bsicons)
library(shinyjs)
library(shinybusy)
library(shinyWidgets)
library(htmltools)
library(markdown)
library(leaflet)
library(leaflet.extras)
library(leaflet.lagniappe)
library(terra)
library(sf)
library(lwgeom)
library(future)
library(promises)
library(ggmap)
library(ggplot2)
library(fs)
library(sfext)             # not using?
###### library(geosphere)
plan('multisession')


source('modalHelp.R')
source('get.WCS.data.R')
source('get.shapefile.R')
source('draw.poly.R')
source('call.make.report.R')
source('make.report.R')
source('make.report.maps.R')
source('layer.stats.R')



home <- c(-75, 42)            # center of NER (approx)
zoom <- 6 

layers <- data.frame(
   which = c('connect', 'connect', 'connect', 'connect', 'iei', 'iei', 'iei', 'iei'),
   workspaces = c('ecoConnect', 'ecoConnect', 'ecoConnect', 'ecoConnect', 'IEI', 'IEI', 'IEI', 'IEI'),
   server.names = c('Forest_fowet', 'Ridgetop', 'Nonfo_wet', 'LR_floodplain_forest', 'iei_regional', 'iei_state', 'iei_ecoregion', 'iei_huc6'),
   pretty.names = c('Forests', 'Ridgetops', 'Wetlands', 'Floodplain forests', 'IEI (region)', 'IEI (state)', 'IEI (ecoregion)', 'IEI (watershed)'),
   radio.names = c('Forests', 'Ridgetops', 'Wetlands', 'Floodplain forests',
                   'Regional', 'State', 'Ecoregion', 'Watershed'))

full.layer.names <- paste0(layers$workspaces, ':', layers$server.names)       # we'll need these for addWMSTiles


WCSserver <- 'https://umassdsl.webgis1.com/geoserver/'                        # our WCS server for downloading data
WMSserver <- 'https://umassdsl.webgis1.com/geoserver/wms'                     # our WMS server for drawing maps


# tool tips
scalingTooltip <- includeMarkdown('inst/scalingTooltip.md')
targetTooltip <- includeMarkdown('inst/targetTooltip.md')
drawTooltip <- includeMarkdown('inst/drawTooltip.md')
uploadTooltip <- includeMarkdown('inst/uploadTooltip.md')
restartTooltip <- includeMarkdown('inst/restartTooltip.md')
getReportTooltip <- includeMarkdown('inst/getReportTooltip.md')
generateReportTooltip <- includeMarkdown('inst/generateReportTooltip.md')
connectTooltip <- includeMarkdown('inst/connectTooltip.md')
ieiTooltip <- includeMarkdown('inst/ieiTooltip.md')
basemapTooltip <- includeMarkdown('inst/basemapTooltip.md')
opacityTooltip <- includeMarkdown('inst/opacityTooltip.md')


# help docs
aboutTool <- includeMarkdown('inst/aboutTool.md')
aboutecoConnect <- includeMarkdown('inst/shortdoc.md')
aboutIEI <- includeMarkdown('inst/aboutIEI.md')



# User interface ---------------------
ui <- page_sidebar(
   theme = bs_theme(bootswatch = 'cerulean', version = 5),   # bslib version defense. Use version_default() to update
   shinyjs::useShinyjs(),
   
   title = 'ecoConnect tool',
   
   sidebar = 
      sidebar(
         #add_busy_spinner(spin = 'fading-circle', position = 'top-left', onstart = TRUE, timeout = 0),   # for debugging
         add_busy_spinner(spin = 'fading-circle', position = 'top-left', onstart = FALSE, timeout = 500),
         use_busy_spinner(spin = 'fading-circle', position = 'top-left'),
         
         # card(
         #    span(('Scaling'),
         #         tooltip(bs_icon('info-circle'), scalingTooltip)),
         #    
         #    sliderInput('scaling', 'ecoConnect scale', 1, 4, 1, step = 1, ticks = FALSE),   # maybe a slider in shinyjs shiny.fluent can label 0 and 4?
         #    checkboxInput('autoscale', 'Scale with zoom', value = TRUE)
         # ),
         
         # card(
         #    downloadButton('quick.report', 'Do it now'),
         #    textOutput('time'),
         # ),
         
         card(
            span(HTML('<h5 style="display: inline-block;">Target area report</h5>'),
                 tooltip(bs_icon('info-circle'), targetTooltip)),
            
            span(span(actionButton('drawPolys', HTML('Draw')),
                      tooltip(bs_icon('info-circle'), drawTooltip),
                      HTML('&nbsp;'), HTML('or&nbsp;')),
                 
                 span(actionButton('uploadShapefile', HTML('Upload')),
                      tooltip(bs_icon('info-circle'), uploadTooltip))
            ),
            
            span(span(actionButton('getReport', HTML('Get report')),
                      tooltip(bs_icon('info-circle'), getReportTooltip)),
                 
                 span(actionButton('restart', HTML('Restart')),
                      tooltip(bs_icon('info-circle'), restartTooltip))
            )
         ),
         
         card(
            actionLink('aboutTool', label = 'About this tool'),
            actionLink('aboutecoConnect', label = 'About ecoConnect'),
            actionLink('aboutIEI', label = 'About the Index of Ecological Integrity'),
            p(HTML('<a href="https://umassdsl.org/" target="_blank" rel="noopener noreferrer">UMass DSL home page</a>')),
            br(),
            tags$img(height = 60, width = 199, src = 'UMass_DSL_logo_v2.png')
         ),
         width = 290
      ),
   
   layout_sidebar(
      sidebar = sidebar(
         position = 'right', 
         width = 220,
         materialSwitch(
            inputId = 'fullscreen',
            label = 'Full screen',
            value = FALSE,
            status = 'default'
         ),
         hr(style = "border-top: 1px solid #000000;"),
         
         # radioButtons('show.layer', label = span(HTML('<h5 style="display: inline-block;">Layer</h5>'), 
         #                                         tooltip(bs_icon('info-circle'), layerTooltip)), 
         #              choiceNames = c(layers$radio.names, 'None'),
         #              choiceValues = c(full.layer.names, 'none'),
         #              selected = character(0)),
         
         radioButtons('connect.layer', label = span(HTML('<h5 style="display: inline-block;">ecoConnect layers</h5>'), 
                                                    tooltip(bs_icon('info-circle'), connectTooltip)), 
                      choiceNames = layers$radio.names[layers$which == 'connect'],
                      choiceValues = full.layer.names[layers$which == 'connect']),
         
         radioButtons('iei.layer', label = span(HTML('<h5 style="display: inline-block;">IEI layers</h5>'), 
                                                tooltip(bs_icon('info-circle'), ieiTooltip)), 
                      choiceNames = layers$radio.names[layers$which == 'iei'],
                      choiceValues = full.layer.names[layers$which == 'iei'],
                      selected = character(0)),
         
         actionButton('no.layers', 'Turn off layers'),
         
         
         sliderInput('opacity', span(HTML('<h5 style="display: inline-block;">Layer opacity</h5>'), 
                                     tooltip(bs_icon('info-circle'), opacityTooltip)), 
                     0, 100, post = '%', value = 50, ticks = FALSE),
         
         hr(style = "border-top: 1px solid #000000;"),
         
         radioButtons('show.basemap', span(HTML('<h5 style="display: inline-block;">Basemap</h5>'),
                                           tooltip(bs_icon('info-circle'), basemapTooltip)),
                      choiceNames = c('Map', 'Topo', 'Imagery'),
                      choiceValues = c('Stadia.StamenTonerLite', 'USGS.USTopo', 'USGS.USImagery'))
         
      ),
      
      leafletOutput('map')
   )
)



# Server -----------------------------
server <- function(input, output, session) {
   shinyjs::disable('restart')
   shinyjs::disable('getReport')           #### disable for testing
   #  shinyjs::disable('quick.report')        #### do it now button is currently broken
   
   #bs_themer()                                 # uncomment to select a new theme
   #  print(getDefaultReactiveDomain())
   
   observeEvent(input$aboutTool, {
      modalHelp(aboutTool, 'About this tool')})
   observeEvent(input$aboutecoConnect, {
      modalHelp(aboutecoConnect, 'About ecoConnect', size = 'l')})
   observeEvent(input$aboutIEI, {
      modalHelp(aboutIEI, 'About the Index of Ecological Integrity')})
   
   
   output$map <- renderLeaflet({                      # ----- Draw static parts of Leaflet map
      leaflet('map',
              options = leafletOptions(maxZoom = 16)) |>
         addScaleBar(position = 'bottomleft') |>
         osmGeocoder(position = 'bottomright', email = 'bcompton@umass.edu') |>
         setView(lng = home[1], lat = home[2], zoom = zoom)
   })
   
   
   
   observeEvent(input$connect.layer, {
      session$userData$show.layer <- input$connect.layer
      updateRadioButtons(inputId ='iei.layer', selected = character(0))
      cat('Selected layer = ', session$userData$show.layer, '\n', sep = '')
   })
   
   # observeEvent(input$show.basemap, {
   #    cat('Drawing basemap ', input$show.basemap, '\n', sep = '')
   #    leafletProxy('map') |>
   #       addProviderTiles(provider = input$show.basemap)
   # })
   
   observeEvent(input$iei.layer, {
      session$userData$show.layer <- input$iei.layer
      updateRadioButtons(inputId ='connect.layer', selected = character(0))
      updateCheckboxInput(inputId = 'no.layers', value = 0)
      cat('Selected layer = ', session$userData$show.layer, '\n', sep = '')
   })
   
   observeEvent(input$no.layers, {
      session$userData$show.layer <- 'none'
      updateRadioButtons(inputId ='iei.layer', selected = character(0))
      updateRadioButtons(inputId ='connect.layer', selected = character(0))
      updateCheckboxInput(inputId = 'no.layers', value = 0)
      cat('Layers off\n', sep = '')
   })##########, ignoreInit = TRUE)
   
   observeEvent(list(input$connect.layer, input$iei.layer, input$show.basemap, 
                     input$opacity), {                                          # ----- Draw dynamic parts of Leaflet map
                        cat('Observed selected layer = ', session$userData$show.layer, '\n', sep = '')
                        cat('Drawing basemap ', input$show.basemap, '\n', sep = '')
                        cat('Opacity = ', input$opacity, '%\n', sep = '')
                        
                        if(length(session$userData$show.layer) != 0 && session$userData$show.layer == 'none')
                           leafletProxy('map') |>
                           addProviderTiles(provider = input$show.basemap) |>
                           removeTiles(layerId = 'dsl.layers')
                        else 
                           leafletProxy('map') |>
                           addProviderTiles(provider = input$show.basemap) |>
                           addWMSTiles(WMSserver, layerId = 'dsl.layers', layers = session$userData$show.layer,
                                       options = WMSTileOptions(opacity = input$opacity / 100))
                     })
   
   observeEvent(input$autoscale, {
      if(input$autoscale)
         shinyjs::disable('scaling')
      else
         shinyjs::enable('scaling')
   })
   
   
   observeEvent(input$drawPolys, {                    # ----- Draw button
      shinyjs::disable('drawPolys')
      shinyjs::disable('uploadShapefile')
      shinyjs::enable('restart')
      
      session$userData$drawn <- TRUE
      proxy <- leafletProxy('map')
      addDrawToolbar(proxy, polygonOptions = drawPolygonOptions(shapeOptions = drawShapeOptions(color = 'purple', fillColor = 'purple')), 
                     polylineOptions = FALSE, circleOptions = FALSE, rectangleOptions = FALSE, markerOptions = FALSE, 
                     circleMarkerOptions = FALSE, editOptions = editToolbarOptions()) 
   })
   
   observeEvent(input$map_draw_all_features, {        # when the first poly is finished, get report becomes available
      if(!is.null(input$map_draw_all_features))
         shinyjs::enable('getReport')
   })
   
   observeEvent(input$uploadShapefile, {              # ----- Upload button
      shinyjs::disable('drawPolys')
      shinyjs::disable('uploadShapefile')
      shinyjs::enable('restart')
      
      
      # do modal dialog to get shapefile
      showModal(modalDialog(
         title = 'Select shapefile to upload',
         fileInput('shapefile', '', accept = c('.shp', '.shx', '.prj'), multiple = TRUE, 
                   placeholder = 'must include .shp, .shx, and .prj', width = '100%'),
         footer = tagList(
            modalButton('OK'),
            actionButton('restart', 'Cancel'))
      ))
      
      session$userData$drawn <- FALSE
      shinyjs::enable('getReport')
   })
   
   observeEvent(input$shapefile, {                    # --- Have uploaded shapefile
      session$userData$poly <- get.shapefile(input$shapefile)
      draw.poly(session$userData$poly)
   })
   
   observeEvent(input$restart, {                    # ----- Restart button
      shinyjs::enable('drawPolys')
      shinyjs::enable('uploadShapefile')
      shinyjs::disable('restart')
      shinyjs::disable('getReport')
      removeModal()                                   # when triggered by cancel button in upload
      
      leafletProxy('map') |>
         removeDrawToolbar(clearFeatures = TRUE) |>
         clearShapes()
   })
   
   
   
   observeEvent(input$getReport, {                    # ----- Get report button
      output$time <- renderText({
         paste('Wait time ', round(session$userData$time, 2), ' sec', sep = '')
      })
      
      
      if(session$userData$drawn)                      #     If drawn polygon,
         session$userData$poly <- geojsonio::geojson_sf(jsonlite::toJSON(input$map_draw_all_features, auto_unbox = TRUE))  #    drawn poly as sf
      
      session$userData$saved <- list(input$proj.name, input$proj.info)
      session$userData$waiting <- TRUE
      
      showModal(modalDialog(                          # --- Modal input to get project name and description
         textInput('proj.name', 'Project name', value = input$proj.name, width = '100%',
                   placeholder = 'Project name for report'),
         textAreaInput('proj.info', 'Project description', value = input$proj.info, 
                       width = '100%', rows = 6, placeholder = 'Optional project description'),
         footer = tagList(
            show_spinner(),
            span(disabled(downloadButton('do.report', 'Generate report')), tooltip(bs_icon('info-circle'), generateReportTooltip)),
            actionButton('cancel.report', 'Cancel')
         )
      ))
      
      
      
      
      # -- Download data while user is typing project info
      session$userData$poly <- st_make_valid(session$userData$poly)    # attempt to fix bad shapefiles
      session$userData$poly.proj <- st_transform(session$userData$poly, 'epsg:3857', type = 'proj') # project to match downloaded rasters
      session$userData$bbox <- as.list(st_bbox(session$userData$poly.proj))
      
      
      xxpoly <<- session$userData$poly
      xxpoly.proj <<- session$userData$poly.proj
      #  st_write(xxpoly, 'C:/GIS/GIS/sample_parcels/name.shp')  # save drawn poly as shapefile
      
      cat('*** PID ', Sys.getpid(), ' asking to download data in the future...\n', sep = '')
      t <- Sys.time()
      downloading <- showNotification('Downloading data...', duration = NULL, closeButton = FALSE)
      
      
      session$userData$the.promise <- future_promise({
         cat('*** PID ', Sys.getpid(), ' is working in the future...\n', sep = '')
         get.WCS.data(WCSserver, layers$workspaces, layers$server.names, session$userData$bbox)    # ----- Download data in the future  
      }) 
      then(session$userData$the.promise, onFulfilled = function(x) {
         cat('*** The promise has been fulfilled!\n')
         enable('do.report')
         hide_spinner()
         removeNotification(downloading)
      }) 
      session$userData$time <- Sys.time() - t
      NULL
   })
   
   
   observeEvent(input$cancel.report, {                            # --- Cancel button from report dialog. Go back to previous values
      removeModal()
      updateTextInput(inputId = 'proj.name', value = session$userData$saved[[1]])
      updateTextInput(inputId = 'proj.info', value = session$userData$saved[[2]])
   })
   
   
   # --- Generate report button from report dialog
   output$do.report <- downloadHandler(
      file = 'report.pdf',
      content = function(f) {
         removeModal()   
         session$userData$the.promise %...>% 
            call.make.report(., f, layers, session$userData$poly, session$userData$poly.proj, 
                             input$proj.name, input$proj.info, session$userData$acres, 
                             quick = FALSE, session = getDefaultReactiveDomain())       
      })
   
   # --- Generate report button from report dialog                ############# For testing reports
   output$quick.report <- downloadHandler(
      file = 'report.pdf',
      content = function(f) {
         make.report(., f, params = xxparams, quick = TRUE)
      }
   )
}

shinyApp(ui, server)


