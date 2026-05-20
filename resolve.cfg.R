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
   #     a list of config fields
   # B. Compton, 20 May 2026


   q <- if(is.null(query_string) || !nzchar(query_string)) list()
        else shiny::parseQueryString(query_string)

   regional <- !identical(tolower(as.character(q[['regional']])), 'false')

   list(
      regional = regional,
      title    = if(regional) 'EcoAssess' else 'Massachusetts EcoAssess'
      # workstream 4 will land more here: switch_label, switch_tooltip,
      # boundary_label, boundary_layers, show_parcels, show_pos, etc.
   )
}
