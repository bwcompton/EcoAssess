'switch.url' <- function(cfg) {

   # switch.url
   # Build the URL that switches to the other mode -- the target of the
   # in-app "switch" link added in workstream 4. Workstream 4 will extend
   # this to also encode the current map view + display state so the reload
   # preserves where the user is.
   #
   # Arguments:
   #     cfg            current session's cfg list (from resolve.cfg)
   # Result:
   #     a relative URL (the query string) to navigate to
   # B. Compton, 20 May 2026


   if(cfg$regional) '?regional=false' else '?regional=true'
}
