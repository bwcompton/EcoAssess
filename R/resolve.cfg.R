'resolve.cfg' <- function(query_string) {

   # resolve.cfg
   # Parse the URL query string and resolve into a per-session mode config list.
   # Called from both ui (request$QUERY_STRING) and server
   # (session$clientData$url_search) so both see the same cfg.
   #
   # Mode is selected by the `regional` query param; defaults TRUE. Only an
   # explicit `?regional=false` flips to the Massachusetts version.
   #
   # The in-app switch link may also carry lng / lat / zoom params (see
   # switch.url) -- when present and valid they become the opening view, so a
   # switch preserves where the user was. When absent, the map opens at the
   # mode's home.
   #
   # cfg drives every UI/server difference between the regional and
   # Massachusetts versions. Resolved once at session start; never changes
   # within a session.
   #
   # Arguments:
   #     query_string   the URL query string after `?` (may be NULL or empty)
   # Result:
   #     a list:
   #        regional        TRUE for the 13-state regional app, FALSE for MA
   #        title           page title
   #        switch.label    current version name, shown by the switch field
   #        boundary.label  label for the show-boundaries checkbox
   #        home.zoom       the mode's overview zoom (for the switch carry test)
   #        view            list(lng, lat, zoom) -- where the map opens
   # B. Compton, 20-22 May 2026


   q <- if(is.null(query_string) || !nzchar(query_string)) list()
        else shiny::parseQueryString(query_string)

   regional <- !identical(tolower(as.character(q[['regional']])), 'false')

   # opening view: the mode's home, unless the switch carried a valid view
   view <- if(regional) list(lng = home.regional[1], lat = home.regional[2], zoom = zoom.regional)
           else         list(lng = home.ma[1],       lat = home.ma[2],       zoom = zoom.ma)

   lng <- suppressWarnings(as.numeric(q[['lng']]))
   lat <- suppressWarnings(as.numeric(q[['lat']]))
   zm  <- suppressWarnings(as.numeric(q[['zoom']]))
   if(length(lng) == 1L && length(lat) == 1L && length(zm) == 1L &&
      is.finite(lng) && is.finite(lat) && is.finite(zm))
      view <- list(lng = lng, lat = lat, zoom = zm)

   list(
      regional       = regional,
      title          = if(regional) 'EcoAssess' else 'Massachusetts EcoAssess',
      switch.label   = if(regional) 'Regional EcoAssess' else 'Massachusetts EcoAssess',
      boundary.label = if(regional) 'Show states and counties' else 'Show counties and towns',
      home.zoom      = if(regional) zoom.regional else zoom.ma,
      view           = view
   )
}
