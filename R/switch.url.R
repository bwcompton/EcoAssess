'switch.url' <- function(cfg, view = NULL) {

   # switch.url
   # Build the relative URL the in-app switch link navigates to. Flips the
   # `regional` flag. If `view` is supplied -- the user had zoomed in past the
   # mode's overview, so make.server passes the current map view -- it is
   # carried as lng/lat/zoom params and the other version opens on the same
   # spot. With no view, the other version opens at its own home.
   #
   # Arguments:
   #     cfg     current session's cfg list (from resolve.cfg)
   #     view    NULL, or list(lng, lat, zoom) to carry across the switch
   # Result:
   #     a relative URL (a query string) to navigate to
   # B. Compton, 20-22 May 2026


   flag <- if(cfg$regional) 'regional=false' else 'regional=true'
   if(is.null(view))
      paste0('?', flag)
   else
      sprintf('?%s&lng=%s&lat=%s&zoom=%s', flag,
              round(view$lng, 5), round(view$lat, 5), view$zoom)
}
