'pos.server' <- function(input, output, session) {

   # pos.server
   # MA-mode protected open space overlay behaviour. Called from make.server
   # alongside parcel.server when the ESRI probe passes.
   #
   # The show.pos checkbox triggers a statewide fetch (LEV_PROT = 'P') via
   # get.pos.C (memoised -- one fetch per R process). Display is zoom-gated:
   # nothing is drawn until the user zooms past pos.zoom, and groupOptions
   # auto-hides the layer if they zoom back out. Unchecking clears the group
   # and resets the drawn flag so a re-check re-adds it.
   #
   # Arguments:
   #     input, output, session   the Shiny server objects from make.server
   # B. Compton, 27 May 2026

   session$userData$pos.drawn <- FALSE

   observe({
      if(!isTRUE(input$show.pos)) {
         if(session$userData$pos.drawn) {
            clearGroup(leafletProxy('map'), 'pos')
            session$userData$pos.drawn <- FALSE
         }
         return()
      }

      req(input$map_zoom)
      if(!isTRUE(input$map_zoom >= pos.zoom)) return()
      if(session$userData$pos.drawn) return()               # already on the map

      pos <- get.pos.C()
      if(is.null(pos)) return()

      leafletProxy('map') |>
         addPolygons(data = sf::st_transform(pos, 4326), group = 'pos',
                     color = '#006400', weight = 2, fillOpacity = 0) |>
         groupOptions('pos', zoomLevels = pos.zoom:16)
      session$userData$pos.drawn <- TRUE
   })
}
