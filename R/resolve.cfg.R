'resolve.cfg' <- function(query_string) {

   # resolve.cfg
   # Parse the URL query string and resolve into a per-session mode config list.
   # Called from both ui (request$QUERY_STRING) and server
   # (session$clientData$url_search) so both see the same cfg.
   #
   # Mode is selected by the `regional` query param; defaults TRUE. Only an
   # explicit `?regional=false` flips to the Massachusetts version -- any other
   # value or no param at all stays regional.
   #
   # cfg drives every UI/server difference between the regional and
   # Massachusetts versions. Resolved once at session start; never changes
   # within a session -- mode switching is a full page reload to a flipped-flag
   # URL (see switch.url).
   #
   # Arguments:
   #     query_string   the URL query string after `?` (may be NULL or empty
   #                    for the base URL)
   # Result:
   #     a list:
   #        regional        TRUE for the 13-state regional app, FALSE for MA
   #        title           page title
   #        switch.label    name of the current version, shown by the switch field
   #        boundary.label  label for the show-boundaries checkbox
   # B. Compton, 20-21 May 2026


   q <- if(is.null(query_string) || !nzchar(query_string)) list()
        else shiny::parseQueryString(query_string)

   regional <- !identical(tolower(as.character(q[['regional']])), 'false')

   list(
      regional       = regional,
      title          = if(regional) 'EcoAssess' else 'Massachusetts EcoAssess',
      switch.label   = if(regional) 'Regional EcoAssess' else 'Massachusetts EcoAssess',
      boundary.label = if(regional) 'Show states and counties' else 'Show counties and towns'
   )
}
