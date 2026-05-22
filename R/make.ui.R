'make.ui' <- function(cfg) {

   # make.ui
   # Build the Shiny UI tree for this session. Branches on cfg (resolved by
   # resolve.cfg from the URL query string) to render either the regional or
   # the Massachusetts version of the app. The Massachusetts version adds a
   # mode-switch field, "Show protected open space" and "Show parcel data"
   # checkboxes, and a "Select parcel(s)" button, and relabels the boundary
   # checkbox. The switch field itself appears in both versions.
   #
   # Arguments:
   #     cfg            current session's cfg list (from resolve.cfg)
   # Result:
   #     a bslib page_sidebar UI tree
   # B. Compton, 20-21 May 2026


   ma <- !cfg$regional         # Massachusetts mode -- gates the MA-only UI deltas

   page_sidebar(
      theme = bs_theme(bootswatch = 'cerulean', version = 5),   # bslib version defense. Use version_default() to update
      useShinyjs(),
      extendShinyjs(script = 'fullscreen.js', functions = c('fullscreen', 'normalscreen', 'is_iOS')),
      tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "fullscreen.css")),      # turn off dark background for fullscreen

      tags$head(tags$script(src = 'matomo.js')),               # add Matomo tracking JS
      tags$head(tags$script(src = 'matomo_heartbeat.js')),     # turn on heartbeat timer
      tags$script(src = 'matomo_events.js'),                   # track popups and help text

      title = cfg$title,

      sidebar =
         sidebar(
            # add_busy_spinner(spin = 'fading-circle', position = 'bottom-left', onstart = TRUE, timeout = 0),   # for debugging
            add_busy_spinner(spin = 'fading-circle', position = 'bottom-left', onstart = FALSE, timeout = 500),
            use_busy_spinner(spin = 'fading-circle', position = 'bottom-left'),

            card(
               tipped(HTML('<h5 style="display: inline-block;">Project area report</h5>'), projectAreaToolTip),

               span(
                  tipped(actionButton('drawPolys', 'Draw'), drawTooltip),
                  HTML('&nbsp;or&nbsp;'),
                  tipped(actionButton('uploadShapefile', 'Upload'), uploadTooltip),
               ),

               if(ma) span(                                    # ----- MA: Select parcel(s)
                  HTML('or&nbsp;'),
                  tipped(actionButton('selectParcels', 'Select parcel(s)'), selectParcelsTooltip)
               ),

               span(
                  tipped(actionButton('getReport', 'Get report'), getReportTooltip),
                  tipped(actionButton('restart', 'Restart'), restartTooltip)
               )
            ),

            card(
               actionLink('aboutTool', label = 'About this site'),
               actionLink('aboutecoConnect', label = 'About ecoConnect'),
               actionLink('aboutIEI', label = 'About the Index of Ecological Integrity'),
               p(HTML('<a href="https://umassdsl.org/" target="_blank" rel="noopener">UMass DSL home page</a>')),
               br(),
               span(                                           # ----- regional <-> MA switch field
                  tipped(cfg$switch.label, if(cfg$regional) regionalVersionTooltip else massachusettsVersionTooltip),
                  HTML('&nbsp;'),
                  tags$a(id = 'switch.mode', 'switch', href = switch.url(cfg))
               ),
               br(),
               span('Version 1.1.3', actionLink('whatsNew', label = 'What\'s new?')),
               br(),
               tags$img(height = 60, width = 199, src = 'UMass_DSL_logo_v2.png')
            ),
            width = 290
         ),

      layout_sidebar(
         sidebar = sidebar(
            position = 'right',
            width = 280,

            card(
               radioButtons('iei.layer', label = tipped(HTML('<h5 style="display: inline-block;">IEI layers</h5>'), ieiTooltip),
                            choiceNames = layers$radio.names[layers$which == 'iei'],
                            choiceValues = full.layer.names[layers$which == 'iei'],
                            selected = character(0))
            ),

            card(
               radioButtons('connect.layer', label = tipped(HTML('<h5 style="display: inline-block;">ecoConnect layers</h5>'), connectTooltip),
                            choiceNames = layers$radio.names[layers$which == 'connect'],
                            choiceValues = full.layer.names[layers$which == 'connect']),

               sliderTextInput('ecoConnectDisplay', tipped(HTML('<h5 style="display: inline-block;">ecoConnect display</h5>'), ecoConnectDisplayTooltip),
                               choices = c('local', 'medium', 'regional'))

            ),

            card(

               sliderInput('opacity', tipped(HTML('<h5 style="display: inline-block;">Layer opacity</h5>'), opacityTooltip),
                           0, 100, post = '%', value = 60, ticks = FALSE),

               actionButton('no.layers', 'Turn off layers')
            ),

            card(
               radioButtons('show.basemap', tipped(HTML('<h5 style="display: inline-block;">Basemap</h5>'), basemapTooltip),
                            choiceNames = c('Simple map', 'Open Street Map', 'Topo map', 'Imagery'),
                            choiceValues = c('Stadia.StamenTonerLite', 'OpenStreetMap.Mapnik', 'USGS.USTopo', 'USGS.USImagery')),
               hr(),
               checkboxInput('show.boundaries', label = cfg$boundary.label, value = FALSE),
               if(ma) checkboxInput('show.pos', label = tipped('Show protected open space', showPOSTooltip), value = FALSE),
               if(ma) checkboxInput('show.parcels', label = tipped('Show parcel data', showParcelsTooltip), value = FALSE),
               checkboxInput('show.usermap', label = 'Show user basemap', value = FALSE),
               tipped(actionButton('upload.usermap', 'Upload user basemap'), usermapTooltip)

            ),

            card(
               materialSwitch(inputId = 'fullscreen', label = 'Full screen', value = FALSE,
                              status = 'default')
            )
         ),

         leafletOutput('map')
      )
   )
}
