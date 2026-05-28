# get.pos.R - fetch MassGIS permanently protected open space, plus the lazy
# layer handle it's fetched through. Auto-loaded from R/.
# B. Compton, 27 May 2026



'pos.layer' <- local({

   # pos.layer()
   # Lazy, process-global handle to the MassGIS POS FeatureServer. Opened
   # (one arc_open) on first call and cached for the life of the R process.
   # Returns NULL if the endpoint can't be opened; get.pos treats NULL as
   # "POS unavailable". esri.probe() is the startup gatekeeper, so by the
   # time this is first called the server is known to be up.

   layer  <- NULL
   opened <- FALSE
   function() {
      if(!opened) {
         layer  <<- tryCatch(arcgislayers::arc_open(pos.url), error = function(e) NULL)
         opened <<- TRUE
      }
      layer
   }
})


'get.pos' <- function() {

   # get.pos
   # Fetch all permanently protected open space (LEV_PROT = 'P') statewide.
   # Returns an sf object in the layer's native CRS, or NULL if unavailable.
   # Intended to be called through get.pos.C (memoised) -- one fetch per
   # R process, shared across all MA-mode sessions.
   # B. Compton, 27 May 2026

   layer <- pos.layer()
   if(is.null(layer)) return(NULL)

   p <- tryCatch(
      arcgislayers::arc_select(layer, where = "LEV_PROT = 'P'"),
      error = function(e) {
         message('POS fetch failed: ', conditionMessage(e))
         NULL
      })
   if(is.null(p) || nrow(p) == 0) return(NULL)
   message(sprintf('POS: fetched %d features', nrow(p)))
   p
}

get.pos.C <- memoise::memoise(get.pos)   # global cache, shared across users
