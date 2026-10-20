'parcel.server' <- function(input, output, session) {

   # parcel.server
   # All Massachusetts-mode parcel behaviour. Called from make.server only when
   # cfg$regional is FALSE (and the parcels endpoint is reachable), so it's a
   # self-contained "module" without the Shiny-module ceremony.
   #
   # Display: the `show.parcels` checkbox draws parcels for the current
   # viewport, zoom-gated, via the smart-hybrid grid (one fetch per uncovered
   # strip; instant when panning back over covered ground).
   #
   # Selection: the Select parcels button enters selection mode -- clicking
   # parcels toggles them in/out of the project area (purple highlight). The
   # dissolved selection is kept current in session$userData$poly, so getReport
   # consumes it through its existing "uploaded shapefile" path with no change.
   # Selection mode is mutually exclusive with Draw / Upload, like those are
   # with each other; Restart clears it.
   #
   # Arguments:
   #     input, output, session   the Shiny server objects from make.server
   # B. Compton, 22 May 2026


   # per-session parcel state
   session$userData$parcels.fetched  <- character(0)   # grid cell keys covered
   session$userData$parcels.drawn    <- character(0)   # parcel ids on the map
   session$userData$parcel.store     <- list()         # id -> sf row, native CRS
   session$userData$parcels.selected <- list()         # id -> sf row, native CRS
   session$userData$selecting        <- FALSE          # TRUE while in selection mode

   # yellow when imagery basemap + no layers; purple otherwise
   parcel.color <- reactive({
      if(isTRUE(input$show.basemap == 'USGS.USImagery') &&
         length(input$connect.layer) == 0 && length(input$iei.layer) == 0)
         'yellow' else 'purple'
   })

   # debounce the pan/zoom firehose
   parcel.view <- reactive(list(zoom = input$map_zoom, b = input$map_bounds)) |>
      debounce(parcels.debounce)

   # draw only not-yet-drawn parcels; stash every geom (native CRS) for selection
   draw.parcels <- function(m, p) {
      if(is.null(p)) return(invisible())
      ids  <- as.character(p[[parcels.id]])
      keep <- !ids %in% session$userData$parcels.drawn
      if(!any(keep)) return(invisible())
      pk  <- p[keep, ]
      idk <- ids[keep]
      for(i in seq_len(nrow(pk)))
         session$userData$parcel.store[[idk[i]]] <- pk[i, ]            # native
      addPolygons(m, data = sf::st_transform(pk, 4326), group = 'parcels',
                  layerId = idk, color = isolate(parcel.color()), weight = 1, fillOpacity = 0,
                  options = pathOptions(pane = 'parcels-pane'))
      session$userData$parcels.drawn <- c(session$userData$parcels.drawn, idk)
   }

   # redraw all drawn parcels when color changes (e.g. basemap or layer toggle)
   observeEvent(parcel.color(), {
      if(!isTRUE(input$show.parcels)) return()
      ids <- session$userData$parcels.drawn
      if(!length(ids)) return()
      m <- leafletProxy('map')
      clearGroup(m, 'parcels')
      geoms <- do.call(rbind, session$userData$parcel.store[ids])
      addPolygons(m, data = sf::st_transform(geoms, 4326), group = 'parcels',
                  layerId = ids, color = parcel.color(), weight = 1, fillOpacity = 0,
                  options = pathOptions(pane = 'parcels-pane'))
      groupOptions(m, 'parcels', zoomLevels = parcels.zoom:16)
   }, ignoreInit = TRUE)

   # ----- viewport-driven parcel display
   observe({
      v <- parcel.view()
      m <- leafletProxy('map')

      if(!isTRUE(input$show.parcels)) {                # display off: clear and reset
         clearGroup(m, 'parcels')
         session$userData$parcels.fetched <- character(0)
         session$userData$parcels.drawn   <- character(0)
         return()
      }

      req(v$b)
      if(!isTRUE(v$zoom >= parcels.zoom)) return()      # too far out -- nothing to fetch

      # smart-hybrid grid: fetch the bounding strip of any uncovered cells
      cells <- parcel.cells(v$b)
      keys  <- mapply(parcel.cell.key, cells$ix, cells$iy)
      miss  <- !keys %in% session$userData$parcels.fetched
      if(any(miss)) {
         mc  <- cells[miss, ]
         ixr <- range(mc$ix)
         iyr <- range(mc$iy)
         bb  <- c(ixr[1] * parcels.grid, iyr[1] * parcels.grid,
                  (ixr[2] + 1L) * parcels.grid, (iyr[2] + 1L) * parcels.grid)
         message(sprintf('parcels: fetching bbox [%s] at zoom %s',
                         paste(round(bb, 4), collapse = ', '), v$zoom))
         # tryCatch so an arc_select / arcpbf failure degrades gracefully
         # instead of crashing the observer (decision 10 spirit)
         p <- tryCatch(get.parcels.C(bb[1], bb[2], bb[3], bb[4]),
                       error = function(e) {
                          message('parcels: fetch FAILED -- ', conditionMessage(e))
                          NULL
                       })
         message(sprintf('parcels: got %s feature(s)', if(is.null(p)) 0 else nrow(p)))
         session$userData$parcels.fetched <- union(session$userData$parcels.fetched, keys[miss])
         draw.parcels(m, p)
      }

      groupOptions(m, 'parcels', zoomLevels = parcels.zoom:16)   # hide when zoomed out
   })

   # redraw the highlight group, dissolve the selection, hand it to getReport
   refresh.selection <- function(m) {
      sel <- session$userData$parcels.selected
      clearGroup(m, 'selected')
      if(!length(sel)) {
         shinyjs::disable('getReport')
         return(invisible())
      }
      hl <- do.call(rbind, unname(sel))                            # native CRS
      addPolygons(m, data = sf::st_transform(hl, 4326), group = 'selected',
                  layerId = paste0('sel_', names(sel)),
                  color = 'purple', weight = 2, fillOpacity = 0.35,
                  options = pathOptions(pane = 'parcels-pane'))
      # dissolve to the project-area polygon. MassGIS parcels carry sub-mm
      # slivers along shared boundaries -> st_make_valid + buffer-0 fallback.
      geoms <- sf::st_make_valid(hl)
      poly  <- tryCatch(sf::st_union(geoms),
                        error = function(e) sf::st_union(sf::st_buffer(geoms, 0)))
      session$userData$poly  <- sf::st_transform(poly, 4326)       # getReport consumes this
      session$userData$drawn <- FALSE                              #   as it would an upload
      shinyjs::enable('getReport')
   }

   # ----- Select parcels: enter selection mode
   observeEvent(input$selectParcels, {
      session$userData$selecting <- TRUE
      session$userData$drawn     <- FALSE
      updateCheckboxInput(session, 'show.parcels', value = TRUE)   # parcels on, locked on
      shinyjs::disable('show.parcels')
      shinyjs::disable('selectParcels')
      shinyjs::disable('drawPolys')                                # mutual exclusion with
      shinyjs::disable('uploadShapefile')                          #   the other two methods
      shinyjs::enable('restart')
   })

   # ----- click a parcel to toggle it in / out of the selection
   observeEvent(input$map_shape_click, {
      if(!isTRUE(session$userData$selecting)) return()   # passive display: ignore parcel clicks
      id <- input$map_shape_click$id
      if(is.null(id)) return()
      sel <- session$userData$parcels.selected
      if(startsWith(id, 'sel_'))                         # clicked a highlight -> deselect
         sel[[sub('^sel_', '', id)]] <- NULL
      else if(!is.null(sel[[id]]))                       # already selected -> toggle off
         sel[[id]] <- NULL
      else {                                             # unselected parcel -> select
         g <- session$userData$parcel.store[[id]]
         if(!is.null(g)) sel[[id]] <- g
      }
      session$userData$parcels.selected <- sel
      refresh.selection(leafletProxy('map'))
   })

   # ----- Draw / Upload disable parcel selection (mutual exclusion, other way)
   observeEvent(input$drawPolys, shinyjs::disable('selectParcels'))
   observeEvent(input$shapefile, shinyjs::disable('selectParcels'))

   # ----- Restart clears the selection and leaves selection mode
   observeEvent(input$restart, {
      session$userData$selecting        <- FALSE
      session$userData$parcels.selected <- list()
      leafletProxy('map') |> clearGroup('selected')
      shinyjs::enable('show.parcels')
      shinyjs::enable('selectParcels')
   })
}
