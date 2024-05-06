# ecoConnect.tool.app.R - ecoConnect and IEI viewing and reporting tool
# Before initial deployment on shinyapps.io, need to restart R and:
#    1
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
library(future)
library(promises)

source('modalHelp.R')
source('get.WCS.info.R')
source('get.WCS.data.R')
source('make.report.R')
source('demo.modal.R')



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
server <- function(input, output, session) {
   shinyjs::disable('startOver')
   #### shinyjs::disable('getReport')          #### disabled for testing
   
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
   
   observeEvent(input$drawPolys, {                    # ----- Draw button
      shinyjs::disable('drawPolys')
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
   
   observeEvent(input$uploadShapefile, {              # ----- Upload button
      shinyjs::disable('drawPolys')
      shinyjs::enable('startOver')
      shinyjs::enable('uploadShapefile')
      
      # now do modal dialog to get shapefile
      showModal(modalDialog(
         title = 'Select shapefile to upload',
         fileInput('filemap', '', accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj'), multiple = TRUE, 
                   placeholder = 'must include .shp, .shx, and .prj', width = '100%'),
         footer = tagList(
            modalButton('OK'),
         actionButton('cancel.shapefile', 'Cancel'))
      ))
      
      print('asked for shapefile; moving on...')
      

      
      session$userData$drawn <- FALSE
      shinyjs::enable('getReport')
      
      if(is.null(session$userData$layer.info))        # Get WCS capabilities if we haven't
         session$userData$layer.info <- get.WCS.info(WCSserver, workspace, layers)
   })
   
   observeEvent(input$filemap, {                   # --- Have uploaded shapefile
      
      print('UPLOADED SHAPEFILE.......................')
      shpdf <- input$filemap
      if(is.null(shpdf)){
         return()
      }
      previouswd <- getwd()
      uploaddirectory <- dirname(shpdf$datapath[1])
      setwd(uploaddirectory)
      for(i in 1:nrow(shpdf)){
         cat(shpdf$datapath[i], '->\n   ', shpdf$name[i], '\n')
         file.rename(shpdf$datapath[i], shpdf$name[i])
      }
      setwd(previouswd)
      
      
      cat(dsn <- paste(uploaddirectory, shpdf$name[grep(pattern="*.shp$", shpdf$name)], sep="/"))
      session$userData$poly <- st_read(dsn)
      
      # Trap errors here if the shapefile is bad
      
       
    #  leafletProxy('map', data = session$userData$poly)
      
      shapefile <<- session$userData$poly   #### for testing
      
      shapefile2 <- st_transform(shapefile, '+proj=longlat +datum=WGS84')
      
      box <- as.list(st_bbox(shapefile2))
      # leaflet(shapefile2) |>
      #    addProviderTiles(provider = 'Stadia.StamenTonerLite') |>
      leafletProxy('map', data = shapefile2) |>
         addPolygons(color = 'green') |>
         #setView(lng = home[1], lat = home[2], zoom = zoom)
         
      flyToBounds(lat1 = box$ymin, lat2 = box$ymax, lng1 = box$xmin, lng2 = box$xmax)
      
      
      print('DONE WITH SHAPEFILE - WE\'VE GOT IT')
      plot(session$userData$poly)
   })
   
   observeEvent(input$cancel.shapefile, {                       # --- Cancel button from upload shapefile dialog. Go back to previous values
      removeModal()
      cat('\n\n*************** Cancel from upload shapefile **************\n\n')
      
      
   })
   
   
   observeEvent(input$startOver, {                    # ----- Restart button
      shinyjs::enable('drawPolys')
      shinyjs::enable('uploadShapefile')
      shinyjs::disable('startOver')
      shinyjs::disable('getReport')
      
      proxy <- leafletProxy('map')
      removeDrawToolbar(proxy, clearFeatures = TRUE)
   })
   
   observeEvent(input$getReport, {                    # ----- Report button
      if(session$userData$drawn)                      #     If drawn polygon,
         session$userData$poly <- geojsonio::geojson_sf(jsonlite::toJSON(input$map_draw_all_features, auto_unbox = TRUE))  #    drawn poly as sf
      else {                                          #    Else uploaded shapefile,
         print('uploaded')
         # session$userData$poly <- ....              #    uploaded poly as sf
      }                                               # Now produce report
      
      session$userData$saved <- list(input$proj.name, input$proj.info)
      
      showModal(modalDialog(                          # --- Modal input to get project name and description
         textInput('proj.name', 'Project name', value = input$proj.name, width = '100%',
                   placeholder = 'Project name for report'),
         textAreaInput('proj.info', 'Project description', value = input$proj.info, 
                       width = '100%', rows = 6,
                       placeholder = 'Optional project description'),
         footer = tagList(
            downloadButton('do.report', 'Generate report'),
            actionButton('cancel.report', 'Cancel')
         )
      ))
      
      # -- Download data while user is typing project info
      cat('\n\n**************** downloading data with future ****************\n')
      cat('\nCalling PID = ', Sys.getpid(), '\n')
      id <- showNotification('Downloading data...', duration = NULL, closeButton = FALSE)
      session$userData$poly <- zzzzzz         ###### REUSE SAME POLY FOR TESTING
      ###  session$userData$poly <- st_transform(session$userData$poly, 'epsg:3857', 'epsg:3857', type = 'proj')       # project to EPSG:3857
      ###   zzzzzz <<- session$userData$poly
      plot(session$userData$poly)
      
      shapefile2 <- st_transform(shapefile, 'epsg:3857', 'epsg:3857', type = 'proj')
      
      ###   
      
      plan('multisession')
      session$userData$layer.data <- future_promise({                                                  ####################### FUTURE CALL ####################
         get.WCS.data(session$userData$layer.info, st_bbox(session$userData$poly))    # download data
      })
      removeNotification(id)
      cat('\n\n**************** done with future call - not blocked yet ****************\n')
      #  zzzz <<- session$userData$layer.data
      #  cat(value(session$userData$layer.data)[['pid']])
   })
   
   observeEvent(input$cancel.report, {                       # --- Cancel button from report dialog. Go back to previous values
      removeModal()
      cat('\n\n*************** ', session$userData$saved[[1]], '**************\n\n')
      updateTextInput(inputId = 'proj.name', value = session$userData$saved[[1]])
      updateTextInput(inputId = 'proj.info', value = session$userData$saved[[2]])
   })
   
   # --- Generate report button from report dialog
   ###output$do.report <- make.report(session$userData$poly, future_promise(session$userData$layer.data), input$proj.name, input$proj.info)     ###### PROMISE ######
   
   output$do.report <- make.report(session$userData$poly, session$userData$layer.data, input$proj.name, input$proj.info)     ###### PROMISE ######
}

shinyApp(ui, server)