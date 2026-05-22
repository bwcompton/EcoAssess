'parcel.server' <- function(input, output, session) {

   # parcel.server
   # All Massachusetts-mode parcel behaviour. Called from make.server only when
   # cfg$regional is FALSE (and the parcels endpoint is reachable), so it's a
   # self-contained "module" without the Shiny-module ceremony.
   #
   # 5a (this increment): display only. The `show.parcels` checkbox draws
   # parcels for the current viewport, zoom-gated, using the smart-hybrid grid
   # (one fetch per uncovered strip; instant when panning back over covered
   # ground). Click-to-select and the project-area hand-off land in 5b/5c.
   #
   # Arguments:
   #     input, output, session   the Shiny server objects from make.server
   # B. Compton, 22 May 2026


   # per-session parcel state
   session$userData$parcels.fetched <- character(0)   # grid cell keys covered
   session$userData$parcels.drawn   <- character(0)   # parcel ids on the map
   session$userData$parcel.store    <- list()         # id -> sf row, native CRS;
                                                       #   kept for 5b selection

   # debounce the pan/zoom firehose
   parcel.view <- reactive(list(zoom = input$map_zoom, b = input$map_bounds)) |>
      debounce(parcels.debounce)

   # draw only not-yet-drawn parcels; stash every geom (native CRS) for 5b
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
                  layerId = idk, color = 'purple', weight = 1, fillOpacity = 0)
      session$userData$parcels.drawn <- c(session$userData$parcels.drawn, idk)
   }

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
         p <- get.parcels.C(ixr[1] * parcels.grid, iyr[1] * parcels.grid,
                            (ixr[2] + 1L) * parcels.grid, (iyr[2] + 1L) * parcels.grid)
         session$userData$parcels.fetched <- union(session$userData$parcels.fetched, keys[miss])
         draw.parcels(m, p)
      }

      groupOptions(m, 'parcels', zoomLevels = parcels.zoom:16)   # hide when zoomed out
   })
}
