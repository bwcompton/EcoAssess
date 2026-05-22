'make.ui' <- function(cfg) {

   # make.ui
   # Build the Shiny UI tree for this session. Branches on cfg (resolved by
   # resolve.cfg from the URL query string) to render either the regional or
   # the Massachusetts version of the app. The Massachusetts version adds a
   # mode-switch field, "Show protected land" and "Show parcel data"
   # checkboxes, and a "Select parcel(s)" button, and relabels the boundary
   # checkbox. The switch field itself appears in both versions.
   #
   # Initial control state (layer, ecoConnect display, basemap, opacity,
   # boundaries) comes from cfg -- carried across a regional <-> MA switch
   # (decision 7), or the regular defaults on a fresh load.
   #
   # Arguments:
   #     cfg            current session's cfg list (from resolve.cfg)
   # Result:
   #     a bslib page_sidebar UI tree
   # B. Compton, 20-22 May 2026


   ma <- !cfg$regional         # Massachusetts mode -- gates the MA-only UI deltas

   # initial control state: carried across a switch by cfg, else the defaults
   iei.vals <- full.layer.names[layers$which == 'iei']
   con.vals <- full.layer.names[layers$which == 'connect']
   iei.sel  <- if(!is.null(cfg$layer) && cfg$layer %in% iei.vals) cfg$layer else character(0)
   con.sel  <- if(is.null(cfg$layer)) con.vals[1]                       # fresh load: first layer
               else if(cfg$layer %in% con.vals) cfg$layer else character(0)
   display.sel  <- if(!is.null(cfg$display) && cfg$display %in% c('local', 'medium', 'regional'))
                      cfg$display else 'local'
   basemap.vals <- c('Stadia.StamenTonerLite', 'OpenStreetMap.Mapnik', 'USGS.USTopo', 'USGS.USImagery')
   basemap.sel  <- if(!is.null(cfg$basemap) && cfg$basemap %in% basemap.vals) cfg$basemap
                   else basemap.vals[1]
   opacity.val  <- if(is.null(cfg$opacity)) 60 else max(0, min(100, cfg$opacity))

   page_sidebar(
      theme = bs_theme(bootswatch = 'cerulean', version = 5),   # bslib version defense. Use version_default() to update
      useShinyjs(),
      extendShinyjs(script = 'fullscreen.js', functions = c('fullscreen', 'normalscreen', 'is_iOS')),
      tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "fullscreen.css")),      # turn off dark background for fullscreen
      tags$head(tags$style(HTML('.shiny-input-container:has(.checkbox) {margin-bottom: -0.75rem;}'))),   # tighten checkbox spacing (.checkbox excludes the Full screen materialSwitch)

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
                  actionLink('switch.mode', 'switch')          # server builds the URL (make.server)
               ),
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
                            choiceValues = iei.vals,
                            selected = iei.sel)
            ),

            card(
               radioButtons('connect.layer', label = tipped(HTML('<h5 style="display: inline-block;">ecoConnect layers</h5>'), connectTooltip),
                            choiceNames = layers$radio.names[layers$which == 'connect'],
                            choiceValues = con.vals,
                            selected = con.sel),

               sliderTextInput('ecoConnectDisplay', tipped(HTML('<h5 style="display: inline-block;">ecoConnect display</h5>'), ecoConnectDisplayTooltip),
                               choices = c('local', 'medium', 'regional'), selected = display.sel)

            ),

            card(

               sliderInput('opacity', tipped(HTML('<h5 style="display: inline-block;">Layer opacity</h5>'), opacityTooltip),
                           0, 100, post = '%', value = opacity.val, ticks = FALSE),

               actionButton('no.layers', 'Turn off layers')
            ),

            card(
               radioButtons('show.basemap', tipped(HTML('<h5 style="display: inline-block;">Basemap</h5>'), basemapTooltip),
                            choiceNames = c('Simple map', 'Open Street Map', 'Topo map', 'Imagery'),
                            choiceValues = basemap.vals,
                            selected = basemap.sel),
               hr(),
               checkboxInput('show.boundaries', label = cfg$boundary.label, value = isTRUE(cfg$boundaries)),
               if(ma) checkboxInput('show.pos', label = tipped('Show protected land', showPOSTooltip), value = FALSE),
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
