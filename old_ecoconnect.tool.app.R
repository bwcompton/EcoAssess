# ecoconnect.tool.app
# ecoConnect site-scoring website
# B. Compton, 4 Apr 2024 (from ecoconnect.viewer.R)



library(shiny)
library(leaflet)
library(markdown)
library(leaflet.lagniappe)
source('modalHelp.R')


home <- c(-75, 42)            # center of NER (approx)
zoom <- 6                     # starting zoom level
opacity = 0.6                 # opacity of layers
opacity.basemap = 0.85        # opacity of basemap

layers <- c('Forest_fowet', 'Nonfo_wet', 'Ridgetop', 'LR_floodplain_forest')
names <- c('Forests', 'Nonforested wetlands', 'Ridgetop systems', 'Large river floodplain forests')

shortdoc <- includeMarkdown('inst/shortdoc.md')             # About ecoConnect



ui <- fluidPage(
   h4(tags$span(HTML('<a href="https://umassdsl.org"
                    target="_blank" rel="noopener noreferrer" style="color:purple">UMass DSL | Designing Sustainable Landscapes</a>'))),
   tags$head(tags$script(src = 'matomo.js')),               # add Matomo tracking JS
   tags$head(tags$script(src = 'matomo_heartbeat.js')),     # turn on heartbeat timer
   tags$script(src = 'matomo_events.js'),                   # track popups and help text
   
   titlePanel('ecoConnect site-scoring tool'),
   
   br(),
   fluidRow(
      column(5, 
             helpText(HTML('Dev version.')),
      ),
      column(2,
             br(),
             p(actionLink('shortdoc', label = 'About ecoConnect')),
             p(HTML('<a href="https://umassdsl.org/data/ecoConnect"
                    target="_blank" rel="noopener noreferrer">ecoConnect home page</a>'))),
      column(5,
             #tags$img(height = 80, src = 'umass_logo.png'),
             #tags$img(height = 60, src = 'necasc_logo.png')
             tags$img(height = 90, src = 'umass_necasc_logos.png')
      ),
   ),      
   mainPanel(
      leafletOutput("map", height = '65vh', width = '95vw')
   )
)


server <- function(input, output, session) {
   
   observeEvent(input$shortdoc, {
      modalHelp(shortdoc, 'About ecoConnect')})
   
   output$map <- renderLeaflet({
      m <- leaflet()
      m <- addTiles(m, urlTemplate = '', attribution = '<a href="https://umassdsl.org"
                    target="_blank" rel="noopener noreferrer">UMass DSL</a>')
      m <- addProviderTiles(m, provider = 'Stadia.StamenTonerLite', options = providerTileOptions(opacity = opacity.basemap))
      
      for(i in 1:length(layers)) {
         m <- m |> addWMSTiles('https://umassdsl.webgis1.com/geoserver/wms', 
                               layers = qq <- paste0('ecoConnect:', layers[i]), group = names[i],            
                               options = WMSTileOptions(opacity = opacity))
      }
      
      addLayersControl(m, overlayGroups = character(0), baseGroups = names,
                       options = layersControlOptions(collapsed = FALSE)) |>
         
         osmGeocoder(position = 'bottomright', email = 'bcompton@umass.edu') |>
         addEasyButton(easyButton(
            icon="fa-crosshairs", title="Locate Me",
            onClick=JS("function(btn, map){map.locate({setView: true}); }"))) |>
         addFullscreen() |>
         addScaleBar(position = 'bottomleft') |>
         setView(lng = home[1], lat = home[2], zoom = zoom)
   })
}

shinyApp(ui, server)
