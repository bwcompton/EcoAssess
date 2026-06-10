'pos.server' <- function(input, output, session) {

   # pos.server
   # MA-mode protected open space overlay. Called from make.server alongside
   # parcel.server when the ESRI probe passes.
   #
   # Same viewport-driven pattern as parcel.server: a per-session coverage
   # ledger tracks which grid cells have been fetched; panning over covered
   # ground costs nothing. pos.grid is coarser than parcels.grid to match
   # the lower zoom trigger. No ID tracking needed (POS is display-only).
   #
   # Arguments:
   #     input, output, session   the Shiny server objects from make.server
   # B. Compton, 27 May 2026

   session$userData$pos.fetched <- character(0)   # grid cell keys covered

   pos.view <- reactive(list(zoom = input$map_zoom, b = input$map_bounds)) |>
      debounce(pos.debounce)

   observe({
      v <- pos.view()
      m <- leafletProxy('map')

      if(!isTRUE(input$show.pos)) {                # display off: clear and reset
         clearGroup(m, 'pos')
         session$userData$pos.fetched <- character(0)
         return()
      }

      req(v$b)
      if(!isTRUE(v$zoom >= pos.zoom)) return()     # too far out -- nothing to fetch

      cells <- pos.cells(v$b)
      keys  <- mapply(pos.cell.key, cells$ix, cells$iy)
      miss  <- !keys %in% session$userData$pos.fetched
      if(any(miss)) {
         mc  <- cells[miss, ]
         ixr <- range(mc$ix)
         iyr <- range(mc$iy)
         bb  <- c(ixr[1] * pos.grid, iyr[1] * pos.grid,
                  (ixr[2] + 1L) * pos.grid, (iyr[2] + 1L) * pos.grid)
         message(sprintf('POS: fetching bbox [%s] at zoom %s',
                         paste(round(bb, 4), collapse = ', '), v$zoom))
         p <- tryCatch(get.pos.C(bb[1], bb[2], bb[3], bb[4]),
                       error = function(e) {
                          message('POS: fetch FAILED -- ', conditionMessage(e))
                          NULL
                       })
         message(sprintf('POS: got %s feature(s)', if(is.null(p)) 0 else nrow(p)))
         session$userData$pos.fetched <- union(session$userData$pos.fetched, keys[miss])
         if(!is.null(p)) {
            addPolygons(m, data = sf::st_transform(p, 4326), group = 'pos',
                        color = '#00DD00', weight = 3, opacity = 1, fillOpacity = 0,
                        options = pathOptions(pane = 'pos-pane'))
            session$sendCustomMessage('applyPosHatch', list())
         }
      }

      groupOptions(m, 'pos', zoomLevels = pos.zoom:16)
   })
}
