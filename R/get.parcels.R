# get.parcels.R - ESRI startup probe, MassGIS parcel fetch, the lazy layer
# handle they're fetched through, and viewport grid helpers. Auto-loaded from
# R/. arcgislayers / memoise are referenced with `::` so they load on demand --
# no library() call, and regional-mode sessions never touch them.
# B. Compton, 22 May 2026



'parcels.layer' <- local({

   # parcels.layer()
   # Lazy, process-global handle to the MassGIS parcels FeatureServer. Opened
   # (one arc_open) on first call and cached for the life of the R process;
   # regional-mode sessions never call it, so they pay nothing. Returns NULL
   # if the endpoint can't be opened -- get.parcels treats NULL as "parcels
   # unavailable" and returns NULL. esri.probe() is the startup gatekeeper;
   # by the time parcels.layer() is first called (on the initial viewport
   # fetch), the server is known to be up.
   # Note: opened once per process, so a mid-session endpoint recovery isn't
   # picked up until the next process; the daily monitor (WS 8) is the backstop.

   layer  <- NULL
   opened <- FALSE
   function() {
      if(!opened) {
         layer  <<- tryCatch(arcgislayers::arc_open(parcels.url), error = function(e) NULL)
         opened <<- TRUE
      }
      layer
   }
})


'esri.probe' <- function() {

   # esri.probe
   # Ping the MassGIS parcels and protected open space FeatureServer endpoints
   # at MA-mode session startup to confirm ESRI is reachable. Uses httr::GET
   # with explicit timeouts -- the same pattern as the GeoServer probe.
   # Parcels gets 6 s. POS gets 6 s if parcels responded (it may be
   # independently down) or 2 s if parcels already failed (outage is already
   # confirmed; no need to linger). Returns TRUE only when both respond with
   # HTTP 200. Called from make.server.
   # B. Compton, 27 May 2026

   parcels.ok <- tryCatch({
      GET(parcels.url, timeout(6))$status_code == 200
   }, error = function(e) {
      message('ESRI parcels probe failed: ', conditionMessage(e))
      FALSE
   })
   message('ESRI parcels probe: ', if(parcels.ok) 'OK' else 'FAILED')

   pos.ok <- tryCatch({
      GET(pos.url, timeout(if(parcels.ok) 6 else 2))$status_code == 200
   }, error = function(e) {
      message('ESRI POS probe failed: ', conditionMessage(e))
      FALSE
   })
   message('ESRI POS probe: ', if(pos.ok) 'OK' else 'FAILED')

   parcels.ok && pos.ok
}


'get.parcels' <- function(xmin, ymin, xmax, ymax) {

   # get.parcels
   # Fetch all MassGIS parcels intersecting a lat/long bounding box. Returns an
   # sf object in the layer's NATIVE CRS (EPSG:26986) -- parcels are kept native
   # and transformed to 4326 only at the addPolygons call (see parcel.server),
   # so the eventual project-area hand-off has no datum round-trip.
   #
   # Arguments:
   #     xmin, ymin, xmax, ymax   bounding box in EPSG:4326 (lat/long degrees)
   # Result:
   #     sf object (native CRS), or NULL if the box is empty or parcels are
   #     unavailable
   # B. Compton, 22 May 2026

   layer <- parcels.layer()
   if(is.null(layer)) return(NULL)

   env <- sf::st_as_sfc(sf::st_bbox(c(xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax),
                                    crs = 4326))
   p <- suppressMessages(
      arcgislayers::arc_select(layer, fields = parcels.id, filter_geom = env))
   if(is.null(p) || nrow(p) == 0) return(NULL)
   p
}

get.parcels.C <- memoise::memoise(get.parcels)   # global cache, shared across users


# Viewport <-> fixed lat/long grid. The grid is only a COVERAGE ledger: when the
# viewport has uncovered cells, parcel.server fetches the bounding strip of the
# missing ones in a single request, so panning back over covered ground costs
# zero fetches. (See PoC #2 for the smart-hybrid rationale.)

'parcel.cells' <- function(b)                                    # grid cells overlapping a viewport
   expand.grid(ix = seq(floor(b$west  / parcels.grid), ceiling(b$east  / parcels.grid) - 1L),
               iy = seq(floor(b$south / parcels.grid), ceiling(b$north / parcels.grid) - 1L))

'parcel.cell.key' <- function(ix, iy) paste(ix, iy, sep = ':')   # stable key for a grid cell
