# Expanded proof-of-concept #2: MA parcel viewport-fetch + click-to-select
# -----------------------------------------------------------------------------
# Companion to dev/implementation-plan.md (section "Parcel display/selection
# design"). THROWAWAY code -- this is here to settle:
#
#   1. Is parcel display smooth when fetched on pan/zoom on realistic towns?
#   2. smart-hybrid grid vs. naive re-query -- flip `dedup_strategy`, compare.
#
# It also proves the hand-off: selected parcels -> dissolved sf in lat/long,
# exactly the shape get.shapefile() returns, so the existing getReport()
# machinery in EcoAssess.app.R can consume it unchanged.
#
# Pattern lifted from DEPMEP.app.R + readMVT::read.viewport.tiles, minus MVT.
#
# B. Compton / Claude, 2026-05-15 (rev 2)
#
# NOTE re editing: if you have this open in RStudio, close it (or don't save)
# while Claude is editing -- a stale RStudio save will clobber on-disk changes.


library(shiny)
library(leaflet)
library(sf)
library(arcgislayers)
library(memoise)


# ---- Tunables ---------------------------------------------------------------
# These are the knobs to play with.

parcels_url <- 'https://services1.arcgis.com/hGdibHYSPO59RG1h/arcgis/rest/services/Massachusetts_Property_Tax_Parcels/FeatureServer/0'
id_field    <- 'LOC_ID'      # MassGIS statewide unique parcel id. Confirmed
                             # unique, string form e.g. "M_133746_940936".
trigger     <- 15            # fetch/show parcels at this Leaflet zoom or closer
max_zoom    <- 19            # PoC only. NOTE: production app caps at 16
                             # (leafletOptions(maxZoom = 16)) -- so either
                             # trigger <= 16, or MA mode raises maxZoom.
dedup_strategy <- 'naive'    # 'grid' = smart hybrid (one fetch for the missing
                             #   strip, instant when revisiting) | 'naive' (one
                             #   fetch per viewport, every time). Flip to compare.
grid_deg    <- 0.01          # grid cell size in degrees (~0.8 km E-W in MA).
                             # Only used by the 'grid' strategy. Tune it.
debounce_ms <- 300           # collapse rapid pan/zoom events

# Default over Warwick (BC's home turf -- sparse, the easy case). Spectrum to
# test: suburban Concord c(-71.349, 42.460); realistic land-trust town
# Petersham c(-72.189, 42.487); extreme/unrealistic Cambridge c(-71.106, 42.375).
home      <- c(-72.34, 42.68)     # Warwick
home_zoom <- 15                   # match `trigger` so parcels show on load

unselected_style <- list(color = 'purple', weight = 1, fillOpacity = 0)
selected_style   <- list(color = 'purple', weight = 2, fillOpacity = 0.35)


# ---- Open the layer once, verify the id field -------------------------------
# Mirrors the startup health-check the real app will do (plan decision 10).

parcel_layer <- tryCatch(
   arc_open(parcels_url),
   error = function(e) stop('Could not open parcels FeatureServer: ', conditionMessage(e))
)

fields_avail <- arcgislayers::list_fields(parcel_layer)$name
message('Parcel layer fields: ', paste(fields_avail, collapse = ', '))
if (!id_field %in% fields_avail)
   stop('id_field "', id_field, '" not in service. Available: ',
        paste(fields_avail, collapse = ', '),
        '  <-- set id_field to the real unique parcel id.')


# ---- Fetch one bbox of parcels (memoised, shared across users) --------------
# Returns sf in EPSG:4326, or NULL if empty. Global memoise => one user's fetch
# serves the others on the shared shinyapps.io session AND throttles the
# volatile ArcGIS endpoint.
#
# CRS diagnosis (shapefile-offset bug): MassGIS native is expected to be
# EPSG:26986 (NAD83 Mass State Plane). NAD83->WGS84 in MA is ~1 m, NOT the
# ~30 m we saw -- so the prime suspect is the proj4 datum string formerly used
# in the dump, not the source SR. This one-shot report prints the real source
# WKID + a sample coord before and after transform so we work from facts.

reported_crs <- FALSE
fetch_bbox <- function(xmin, ymin, xmax, ymax) {
   env <- st_as_sfc(st_bbox(c(xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax),
                            crs = 4326))
   p <- arc_select(parcel_layer, fields = id_field, filter_geom = env)
   if (is.null(p) || nrow(p) == 0) return(NULL)

   if (!reported_crs) {
      reported_crs <<- TRUE
      src <- st_crs(p)
      pt0 <- suppressWarnings(st_coordinates(st_centroid(st_geometry(p)[1]))[1, ])
      p4  <- st_transform(p, 4326)
      pt1 <- suppressWarnings(st_coordinates(st_centroid(st_geometry(p4)[1]))[1, ])
      message('=== SOURCE CRS from arc_select (before transform) ===')
      message('  ', format(src)[1], '  EPSG: ',
              ifelse(is.na(src$epsg), '<none>', src$epsg))
      message(sprintf('  sample centroid  src: %s', paste(round(pt0, 3), collapse = ', ')))
      message(sprintf('  sample centroid 4326: %s', paste(round(pt1, 6), collapse = ', ')))
      message('=====================================================')
   }
   st_transform(p, 4326)        # EPSG code, NOT a proj4 datum string
}
if (!exists('fetch_bbox_C'))            # global, a la readMVT::read.tile.C
   fetch_bbox_C <<- memoise(fetch_bbox)


# ---- Grid helpers -----------------------------------------------------------
# The cell grid is only a COVERAGE ledger -- not the fetch granularity.
# (Production could use slippy tiles like readMVT for equal-area cells; a
# degree grid is plenty for a PoC and MA's narrow latitude band makes the
# distortion negligible.)

cells_for_viewport <- function(b) {
   ix <- seq(floor(b$west  / grid_deg), ceiling(b$east  / grid_deg) - 1L)
   iy <- seq(floor(b$south / grid_deg), ceiling(b$north / grid_deg) - 1L)
   expand.grid(ix = ix, iy = iy)
}
cell_key <- function(ix, iy) paste(ix, iy, sep = ':')


# ---- UI ---------------------------------------------------------------------
ui <- fluidPage(
   tags$head(tags$style('#panel{position:absolute;top:80px;right:20px;z-index:1000;
      background:#fffe;padding:10px 14px;border-radius:6px;font:13px/1.4 sans-serif;
      box-shadow:0 1px 4px #0003}')),
   leafletOutput('map', height = '100vh'),
   absolutePanel(id = 'panel',
      strong('Parcel select PoC'), br(),
      textOutput('status', inline = TRUE), br(), br(),
      actionButton('dump',  'Dump selection -> sf', class = 'btn-sm btn-primary'),
      actionButton('clear', 'Clear', class = 'btn-sm')
   )
)


# ---- Server -----------------------------------------------------------------
server <- function(input, output, session) {

   # per-user state (NOT global -- would bleed across users on shinyapps.io)
   session$userData$fetched  <- character(0)   # grid cell keys covered
   session$userData$drawn    <- character(0)   # parcel ids already on the map
   session$userData$store    <- list()         # id -> sf row, EVERY fetched
                                               #   geom: lets selection be a
                                               #   local lookup (no ESRI hit)
   session$userData$selected <- list()         # id -> sf row (4326)

   rv <- reactiveValues(sel = 0, fetch = NA, render = NA, select = NA)

   output$map <- renderLeaflet({
      leaflet(options = leafletOptions(maxZoom = max_zoom,
                                       boxZoom = FALSE,             # kill shift-drag zoom
                                       doubleClickZoom = FALSE)) |> # and dbl-click zoom
         addProviderTiles('CartoDB.Positron') |>
         setView(home[1], home[2], home_zoom) |>
         addScaleBar(position = 'bottomleft')
   })

   # debounce the firehose of pan/zoom events
   view <- reactive(list(zoom = input$map_zoom, b = input$map_bounds)) |>
      debounce(debounce_ms)

   # draw only not-already-drawn parcels; stash EVERY geom for instant select
   draw_parcels <- function(m, p) {
      if (is.null(p)) return(invisible())
      ids  <- as.character(p[[id_field]])
      keep <- !ids %in% session$userData$drawn
      if (!any(keep)) return(invisible())
      pk <- p[keep, ]; idk <- ids[keep]
      for (i in seq_len(nrow(pk)))
         session$userData$store[[idk[i]]] <- pk[i, ]
      addPolygons(m, data = pk, group = 'parcels', layerId = idk,
                  color = unselected_style$color, weight = unselected_style$weight,
                  fillOpacity = unselected_style$fillOpacity)
      session$userData$drawn <- c(session$userData$drawn, idk)
   }

   # ---- the new reactive: fetch parcels for the viewport -------------------
   observe({
      v <- view()
      req(v$zoom, v$b)
      if (!isTRUE(v$zoom >= trigger)) return()
      m <- leafletProxy('map')
      tf <- tr <- 0

      if (dedup_strategy == 'naive') {
         # re-query the exact viewport every time; wipe and redraw.
         b <- v$b
         tf <- system.time(p <- fetch_bbox_C(b$west, b$south, b$east, b$north))['elapsed']
         clearGroup(m, 'parcels')
         session$userData$drawn <- character(0)
         tr <- system.time(draw_parcels(m, p))['elapsed']

      } else {
         # SMART grid: the cell ledger only records what's covered. When the
         # viewport has uncovered cells, do ONE fetch of the missing cells'
         # bounding strip (naive speed) and mark them covered. Revisiting
         # covered ground costs zero fetches -> instant pan-back.
         cells <- cells_for_viewport(v$b)
         keys  <- mapply(cell_key, cells$ix, cells$iy)
         miss  <- !keys %in% session$userData$fetched
         if (any(miss)) {
            mc  <- cells[miss, ]
            ixr <- range(mc$ix); iyr <- range(mc$iy)
            tf  <- system.time(
               p <- fetch_bbox_C(ixr[1] * grid_deg, iyr[1] * grid_deg,
                                 (ixr[2] + 1L) * grid_deg, (iyr[2] + 1L) * grid_deg)
            )['elapsed']
            session$userData$fetched <- union(session$userData$fetched, keys[miss])
            tr <- system.time(draw_parcels(m, p))['elapsed']
         }
         # else: fully covered -> nothing to do (the win)
      }

      groupOptions(m, 'parcels', zoomLevels = trigger:max_zoom)
      rv$fetch <- tf; rv$render <- tr
      message(sprintf('[%s] fetch %.0f ms | render %.0f ms | on map: %d',
                       dedup_strategy, 1000 * tf, 1000 * tr,
                       length(session$userData$drawn)))
   })

   # ---- click to toggle selection -----------------------------------------
   # Highlight polygons sit on top with layerId "sel_<id>"; base parcels are
   # "<id>". Click unselected -> "<id>" (select); click selected -> "sel_<id>"
   # (deselect). Geometry comes from the in-memory store -- NO ESRI round-trip.
   observeEvent(input$map_shape_click, {
      id <- input$map_shape_click$id
      if (is.null(id)) return()
      ts  <- Sys.time()
      sel <- session$userData$selected

      if (startsWith(id, 'sel_')) {
         sel[[sub('^sel_', '', id)]] <- NULL
      } else if (!is.null(sel[[id]])) {
         sel[[id]] <- NULL
      } else {
         g <- session$userData$store[[id]]               # instant, local
         if (is.null(g))                                  # rare fallback only
            g <- tryCatch(st_transform(arc_select(parcel_layer, fields = id_field,
                     where = sprintf("%s = '%s'", id_field, id)), 4326),
                     error = function(e) NULL)
         if (!is.null(g) && nrow(g)) sel[[id]] <- g
      }
      session$userData$selected <- sel

      m <- leafletProxy('map') |> clearGroup('selected')
      if (length(sel)) {
         hl <- do.call(rbind, unname(sel))
         addPolygons(m, data = hl, group = 'selected',
                     layerId = paste0('sel_', names(sel)),
                     color = selected_style$color, weight = selected_style$weight,
                     fillOpacity = selected_style$fillOpacity)
      }
      rv$select <- as.numeric(Sys.time() - ts, units = 'secs')
      rv$sel <- length(sel)
   })

   output$status <- renderText({
      ms <- function(x) if (is.na(x)) 0 else 1000 * x
      sprintf('strategy %s | sel %d | fetch %.0f ms | render %.0f ms | select %.0f ms',
              dedup_strategy, rv$sel, ms(rv$fetch), ms(rv$render), ms(rv$select))
   })

   observeEvent(input$clear, {
      session$userData$selected <- list()
      rv$sel <- 0
      leafletProxy('map') |> clearGroup('selected')
   })

   # ---- prove the hand-off to the existing project-area machinery ----------
   observeEvent(input$dump, {
      sel <- session$userData$selected
      if (!length(sel)) { showNotification('Nothing selected.'); return() }

      # exactly what get.shapefile(merge = TRUE) produces: dissolved, lat/long.
      # EPSG:4326, NOT '+proj=longlat +datum=WGS84' -- the proj4 datum string
      # picks a different PROJ pipeline and is the prime suspect for the offset.
      poly <- do.call(rbind, unname(sel)) |>
         st_union() |>
         st_transform(4326)

      acres <- sum(as.vector(st_area(poly)) * 247.105e-6)   # same factor as app
      f <- file.path(tempdir(), 'poc_selection.shp')
      st_write(st_sf(geometry = poly), f, delete_dsn = TRUE, quiet = TRUE)

      cat('\n--- hand-off object (drop straight into session$userData$poly) ---\n')
      print(poly)
      cat(sprintf('parcels: %d   dissolved area: %.2f acres\n', length(sel), acres))
      cat('written: ', f, '\n', sep = '')
      showNotification(sprintf('%d parcels, %.1f acres -> %s',
                               length(sel), acres, f), duration = 8)
   })
}

shinyApp(ui, server)
