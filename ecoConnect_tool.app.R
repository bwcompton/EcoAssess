# ecoConnect.tool.app.R - ecoConnect and IEI viewing and reporting tool
# Before initial deployment on shinyapps.io, need to restart R and:
#    library(remotes); install_github('https://github.com/trafficonese/leaflet.extras.git'); install_github('bwcompton/leaflet.lagniappe')
# B. Compton, 19 Apr-17 May 2024



library(shiny)
library(bslib)
library(bsicons)
library(shinyjs)
library(shinybusy)
library(htmltools)
library(markdown)
library(leaflet)
# remotes::install_github('https://github.com/trafficonese/leaflet.extras.git')   # need until >= v. 1.0.1 is released
library(leaflet.extras)
library(leaflet.lagniappe)
library(terra)
library(sf)
library(lwgeom)
library(future)
library(promises)
plan('multisession')


source('modalHelp.R')
source('get.WCS.info.R')
source('get.WCS.data.quick.R')  #########
source('make.report.R')
source('demo.modal.R')
source('get.shapefile.R')
source('draw.poly.R')
source('layer.stats.R')



home <- c(-75, 42)            # center of NER (approx)
zoom <- 6 

workspace <- 'ecoConnect'
layers <- c('Forest_fowet', 'Ridgetop', 'Nonfo_wet', 'LR_floodplain_forest')
WCSserver <- 'https://umassdsl.webgis1.com/geoserver/ecoConnect/ows'    # our WCS server for downloading data
WMSserver <- 'https://umassdsl.webgis1.com/geoserver/wms'               # our WMS server for drawing maps

# tool tips
scalingInfo <- includeMarkdown('inst/scalingInfo.md')
targetInfo <- includeMarkdown('inst/targetInfo.md')
drawInfo <- includeMarkdown('inst/drawInfo.md')
uploadInfo <- includeMarkdown('inst/uploadInfo.md')
restartInfo <- includeMarkdown('inst/restartInfo.md')
downloadInfo <- includeMarkdown('inst/downloadInfo.md')

# help docs
aboutTool <- includeMarkdown('inst/aboutTool.md')
aboutecoConnect <- includeMarkdown('inst/shortdoc.md')
aboutIEI <- includeMarkdown('inst/aboutIEI.md')



# User interface ---------------------
ui <- page_sidebar(
   theme = bs_theme(bootswatch = 'cerulean'),
   
   title = 'ecoConnect tool',
   
   sidebar = 
      sidebar(
         add_busy_spinner(spin = 'fading-circle', position = 'top-left', onstart = TRUE, timeout = 0),   # for debugging
         #add_busy_spinner(spin = 'fading-circle', position = 'top-right', onstart = FALSE, timeout = 500),
         
         
         card(
            span(('Scaling'),
                 tooltip(bs_icon('info-circle', title = 'About Scaling'), scalingInfo)),
            
            sliderInput('scaling', 'ecoConnect scale', 1, 4, 1, step = 1, ticks = FALSE),   # maybe a slider in shinyjs shiny.fluent can label 0 and 4?
            checkboxInput('autoscale', 'Scale with zoom', value = TRUE)
         ),
         
         card(
            radioButtons('synch', label = NULL, choiceNames = list('Synch', 'Asynch'), choiceValues = list(TRUE, FALSE), selected = FALSE),
            textOutput('time')
         ),
         
         card(
            span(('Target area report'),
                 tooltip(bs_icon('info-circle', title = 'About target area'), targetInfo)),
            
            span(span(actionButton('drawPolys', HTML('Draw')),
                      tooltip(bs_icon('info-circle', title = 'About Draw polys'), drawInfo),
                      HTML('&nbsp;')),
                 
                 span(actionButton('uploadShapefile', HTML('Upload')),
                      tooltip(bs_icon('info-circle', title = 'About Upload shapefile'), uploadInfo),
                      HTML('&nbsp;')),
                 
                 span(actionButton('startOver', HTML('Restart')),
                      tooltip(bs_icon('info-circle', title = 'About Start over'), restartInfo))),
            
            span(actionButton('getReport', HTML('Get report')),
                 tooltip(bs_icon('info-circle', title = 'About Get report'), downloadInfo))
         ),
         
         card(
            actionLink('aboutTool', label = 'About this tool'),
            actionLink('aboutecoConnect', label = 'About ecoConnect'),
            actionLink('aboutIEI', label = 'About the Index of Ecological Integrity'),
            p(HTML('<a href="https://umassdsl.org/" target="_blank" rel="noopener noreferrer">UMass DSL home page</a>')),
            br(),
            tags$img(height = 60, width = 199, src = 'UMass_DSL_logo_v2.png')
         ),
         width = 380
      ),
   
   leafletOutput('map'),
   shinyjs::useShinyjs()
)



# Server -----------------------------
server <- function(input, output, session) {
   shinyjs::disable('startOver')
   shinyjs::disable('getReport')           #### disable for testing
   
   #bs_themer()                                 # uncomment to select a new theme
   
   session$userData$synch <- FALSE
   
   observeEvent(input$aboutTool, {
      modalHelp(aboutTool, 'About this tool')})
   observeEvent(input$aboutecoConnect, {
      modalHelp(aboutecoConnect, 'About ecoConnect', size = 'l')})
   observeEvent(input$aboutIEI, {
      modalHelp(aboutIEI, 'About the Index of Ecological Integrity')})
   
   
   card( 
      output$map <- renderLeaflet({
         leaflet() |>
            addProviderTiles(provider = 'Stadia.StamenTonerLite') |>
            addWMSTiles(WMSserver, layers = paste0(workspace, ':', layers[1]),        
                        options = WMSTileOptions(opacity = 0.5)) |>
            addFullscreenControl(position = "topleft", pseudoFullscreen = FALSE) |>
            # addDrawToolbar(polylineOptions = FALSE, circleOptions = FALSE, rectangleOptions = FALSE, 
            #                markerOptions = FALSE, circleMarkerOptions = FALSE, editOptions = editToolbarOptions()) |>
            addScaleBar(position = 'bottomleft') |>
            osmGeocoder(position = 'bottomright', email = 'bcompton@umass.edu') |>
            setView(lng = home[1], lat = home[2], zoom = zoom)
      })
   )
   
   observeEvent(input$autoscale, {
      if(input$autoscale)
         shinyjs::disable('scaling')
      else
         shinyjs::enable('scaling')
   })
   
   observeEvent(input$synch, {
      session$userData$synch <- input$synch
   })
   

   observeEvent(input$drawPolys, {                    # ----- Draw button
      shinyjs::disable('drawPolys')
      shinyjs::disable('uploadShapefile')
      shinyjs::enable('startOver')
      #  shinyjs::enable('getReport')
      
      session$userData$drawn <- TRUE
      proxy <- leafletProxy('map')
      addDrawToolbar(proxy, polylineOptions = FALSE, circleOptions = FALSE, rectangleOptions = FALSE, 
                     markerOptions = FALSE, circleMarkerOptions = FALSE, editOptions = editToolbarOptions()) 
   })
   
   observeEvent(input$map_draw_all_features, {        # when the first poly is finished, get report becomes available
      if(!is.null(input$map_draw_all_features))
         shinyjs::enable('getReport')
   })
   
   observeEvent(input$uploadShapefile, {              # ----- Upload button
      shinyjs::disable('drawPolys')
      shinyjs::disable('uploadShapefile')
      shinyjs::enable('startOver')
      
      cat('synch = ', session$userData$synch, '\n', sep = '')
      
      # do modal dialog to get shapefile
      showModal(modalDialog(
         title = 'Select shapefile to upload',
         fileInput('shapefile', '', accept = c('.shp', '.shx', '.prj'), multiple = TRUE, 
                   placeholder = 'must include .shp, .shx, and .prj', width = '100%'),
         footer = tagList(
            modalButton('OK'),
            actionButton('startOver', 'Cancel'))
      ))
      
      session$userData$drawn <- FALSE
      shinyjs::enable('getReport')
   })
   
   observeEvent(input$shapefile, {                    # --- Have uploaded shapefile
      session$userData$poly <- get.shapefile(input$shapefile)
      draw.poly(session$userData$poly)
   })
   
   observeEvent(input$startOver, {                    # ----- Restart button
      shinyjs::enable('drawPolys')
      shinyjs::enable('uploadShapefile')
      shinyjs::disable('startOver')
      shinyjs::disable('getReport')
      removeModal()                                   # when triggered by cancel button in upload
      
      leafletProxy('map') |>
         removeDrawToolbar(clearFeatures = TRUE) |>
         removeShape('poly')
   })
   
   observeEvent(input$getReport, {                    # ----- Get report button
      output$time <- renderText({
         paste('Wait time ', round(session$userData$time, 2), ' sec', sep = '')
      })
      
      if(session$userData$drawn)                      #     If drawn polygon,
         session$userData$poly <- geojsonio::geojson_sf(jsonlite::toJSON(input$map_draw_all_features, auto_unbox = TRUE))  #    drawn poly as sf
      
      session$userData$saved <- list(input$proj.name, input$proj.info)
      showModal(modalDialog(                          # --- Modal input to get project name and description
         textInput('proj.name', 'Project name', value = input$proj.name, width = '100%',
                   placeholder = 'Project name for report'),
         textAreaInput('proj.info', 'Project description', value = input$proj.info, 
                       width = '100%', rows = 6, placeholder = 'Optional project description'),
         footer = tagList(
            downloadButton('do.report', 'Generate report'),
            actionButton('cancel.report', 'Cancel')
         )
      ))
      
      # -- Download data while user is typing project info
      session$userData$acres <- sum(as.vector(st_area(session$userData$poly)) * 247.105e-6)
      session$userData$poly <- st_transform(session$userData$poly, 'epsg:3857', 'epsg:3857', type = 'proj') # project to match downloaded rasters
      session$userData$bbox <- as.list(st_bbox(session$userData$poly))
      
      if(session$userData$synch) {  
         cat('Downloading data synchronously...\n')                                   # SYNCH
         t <- Sys.time()
         session$userData$data <- get.WCS.data.quick(WCSserver, layers, session$userData$bbox)    # download data  
         session$userData$time <- Sys.time() - t
      } else {
         plan('multisession')                                           # ASYNCH
         cat('*** PID ', Sys.getpid(), ' asking to download data in the future...\n')
         t <- Sys.time()
         session$userData$the.promise <- future_promise({
            cat('*** PID ', Sys.getpid(), ' is working in the future...\n')
            get.WCS.data.quick(WCSserver, layers, session$userData$bbox)    # download data  
         }) 
         session$userData$time <- Sys.time() - t
         return()
      }
   })
   
   
   observeEvent(input$cancel.report, {                       # --- Cancel button from report dialog. Go back to previous values
      removeModal()
      updateTextInput(inputId = 'proj.name', value = session$userData$saved[[1]])
      updateTextInput(inputId = 'proj.info', value = session$userData$saved[[2]])
   })
   
   
   # --- Generate report button from report dialog                # ASYNCH
   output$do.report <- downloadHandler(
      file = 'report.pdf',
      content = function(f) {
         if(session$userData$synch) {  
            cat('------------ doing SYNCH report ------------\n')
            make.report(session$userData$data, f, input$proj.name, input$proj.info, session$userData$acres)
         } else {
            cat('------------ doing ASYNCH report ------------\n')
            # Content needs to receive promise as return value, so including resolution
            session$userData$the.promise %...>% make.report(., f, input$proj.name, input$proj.info, session$userData$acres)
         }
      }
   )
}

shinyApp(ui, server)