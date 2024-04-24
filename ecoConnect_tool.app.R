# ecoConnect.tool.app.R - ecoConnect and IEI viewing and reporting tool
# Before initial deployment on shinyapps.io, need to restart R and:
#    library(remotes); install_github('https://github.com/trafficonese/leaflet.extras.git'); install_github('bwcompton/leaflet.lagniappe')
# B. Compton, 19 Apr 2024



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
library(ows4R)

source('modalHelp.R')
source('get.WCS.info.R')
source('get.WCS.data.R')
source('make.report.R')



home <- c(-75, 42)            # center of NER (approx)
zoom <- 6 

workspace <- 'ecoConnect'
layers <- c('Forest_fowet', 'Ridgetop', 'Nonfo_wet', 'LR_floodplain_forest')
WMSserver <- 'https://umassdsl.webgis1.com/geoserver/wms'               # our WMS server for drawing maps
WCSserver <- 'https://umassdsl.webgis1.com/geoserver/ecoConnect/ows'    # our WCS server for downloading data

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
         add_busy_spinner(spin = 'fading-circle', position = 'top-right', onstart = FALSE, timeout = 500),
         
         card(
            span(('Scaling'),
                 tooltip(bs_icon('info-circle', title = 'About Scaling'), scalingInfo)),
            
            sliderInput('scaling', 'ecoConnect scale', 1, 4, 1, step = 1, ticks = FALSE),
            checkboxInput('autoscale', 'Scale with zoom', value = TRUE)
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
shinyApp(ui, function(input, output, session) {
   shinyjs::disable('startOver')
   shinyjs::disable('getReport')
   
   #bs_themer()
   
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
   
   observeEvent(input$drawPolys, {                    # --- Draw button
      shinyjs::disable('uploadShapefile')
      shinyjs::enable('startOver')
      #  shinyjs::enable('getReport')
      
      session$userData$drawn <- TRUE
      proxy <- leafletProxy('map')
      addDrawToolbar(proxy, polylineOptions = FALSE, circleOptions = FALSE, rectangleOptions = FALSE, 
                     markerOptions = FALSE, circleMarkerOptions = FALSE, editOptions = editToolbarOptions()) 
      
      if(is.null(session$userData$layer.info))        # Get WCS capabilities if we haven't
         session$userData$layer.info <- get.WCS.info(WCSserver, workspace, layers)
   })
   
   observeEvent(input$map_draw_all_features, {        # when the first poly is finished, get report becomes available
      if(!is.null(input$map_draw_all_features))
         shinyjs::enable('getReport')
   })
   
   observeEvent(input$uploadShapefile, {              # --- Upload button
      shinyjs::disable('drawPolys')
      shinyjs::enable('startOver')
      shinyjs::enable('uploadShapefile')
      
      # now do modal dialog to get shapefile
      
      session$userData$drawn <- FALSE
      shinyjs::enable('getReport')
      
      if(is.null(session$userData$layer.info))        # Get WCS capabilities if we haven't
         session$userData$layer.info <- get.WCS.info(WCSserver, workspace, layers)
   })
   
   observeEvent(input$startOver, {                    # --- Restart button
      shinyjs::enable('drawPolys')
      shinyjs::enable('uploadShapefile')
      shinyjs::disable('startOver')
      shinyjs::disable('getReport')
      
      proxy <- leafletProxy('map')
      removeDrawToolbar(proxy, clearFeatures = TRUE)
   })
   
   observeEvent(input$getReport, {                    # --- Report button
      if(session$userData$drawn)                      #     If drawn polygon,
         poly <- geojsonio::geojson_sf(jsonlite::toJSON(input$map_draw_all_features, auto_unbox = TRUE))     #    drawn poly as sf
      else {                                          #    Else uploaded shapefile,
         print('uploaded')
         # poly <- ....                               #    uploaded poly as sf
      }                                               # Now produce report
      
      # ask for project name and info paragraph here, so we can download data while the user types
      
      poly <- st_transform(poly, 'epsg:3857', 'epsg:3857', type = 'proj')                          # project to EPSG:3857
      session$userData$layer.data <- get.WCS.data(session$userData$layer.info, st_bbox(poly))      # download data
      
      proj.name <- 'Big fat conservation project'
      proj.info <- 'This is a target area we\'ve been looking at, wondering if it has high conseravtion value.'
      
      make.report(poly, session$userData$layer.data, proj.name, proj.info)
   })
})
