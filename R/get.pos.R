# get.pos.R - fetch MassGIS protected open space for a viewport, plus the
# lazy layer handle and viewport grid helpers. Same pattern as get.parcels.R
# but with a coarser grid scaled to pos.zoom. Auto-loaded from R/.
# B. Compton, 27 May 2026



'pos.layer' <- local({

   # pos.layer()
   # Lazy, process-global handle to the MassGIS POS FeatureServer. Opened
   # (one arc_open) on first call and cached for the life of the R process.
   # Returns NULL if the endpoint can't be opened. esri.probe() is the
   # startup gatekeeper, so by the time this is first called the server is
   # known to be up.

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


'get.pos' <- function(xmin, ymin, xmax, ymax) {

   # get.pos
   # Fetch permanently protected open space (LEV_PROT = 'P') intersecting a
   # lat/long bounding box. Returns an sf object in the layer's native CRS,
   # or NULL if the box is empty or POS is unavailable.
   #
   # Arguments:
   #     xmin, ymin, xmax, ymax   bounding box in EPSG:4326 (lat/long degrees)
   # Result:
   #     sf object (native CRS), or NULL
   # B. Compton, 27 May 2026

   layer <- pos.layer()
   if(is.null(layer)) return(NULL)

   env <- sf::st_as_sfc(sf::st_bbox(c(xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax),
                                    crs = 4326))
   p <- arcgislayers::arc_select(layer, filter_geom = env, where = "LEV_PROT = 'P'")
   if(is.null(p) || nrow(p) == 0) return(NULL)
   p
}

get.pos.C <- memoise::memoise(get.pos)   # global cache, shared across users


'pos.cells' <- function(b)
   expand.grid(ix = seq(floor(b$west  / pos.grid), ceiling(b$east  / pos.grid) - 1L),
               iy = seq(floor(b$south / pos.grid), ceiling(b$north / pos.grid) - 1L))

'pos.cell.key' <- function(ix, iy) paste(ix, iy, sep = ':')
