# MA EcoAssess — Implementation Plan

> Living document. Update as decisions change. Companion: `dev/work-log.md`.
> Roadmap source: `C:\Work\etc\Obsidian\MA EcoAssess roadmap.md` (not in repo) —
> owned by BC, kept current for reference. This plan + the work log are
> Claude-maintained (BC may also edit).
> Last updated: 2026-05-15

## Goal

Extend EcoAssess with a Massachusetts-specific mode, funded by the MA Division
of Conservation Services. Single codebase, two behaviors selected at runtime.
Primary new capability: select one or more MassGIS parcels as a project area,
in addition to the existing draw-polygon and upload-shapefile paths.

## Resolved architecture decisions

| #   | Decision                                                                                                                                                                                                                                                                                                                                    |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Single codebase**, not a fork. ~90% shared.                                                                                                                                                                                                                                                                                               |
| 2   | Mode chosen by URL query param → `regional` flag, **default TRUE** (regional).                                                                                                                                                                                                                                                              |
| 3   | `ui <- function(request)` so the query string is available at UI build time. Resolve mode once into a **`cfg` list**; rest of UI/server reads `cfg`.                                                                                                                                                                                        |
| 4   | **Single shinyapps.io instance** (near-instant switching beats clean analytics separation).                                                                                                                                                                                                                                                 |
| 5   | Per-mode Matomo via custom dimension / virtual pageview path set from `cfg`.                                                                                                                                                                                                                                                                |
| 6   | "Switch version" = navigate to same app with flag flipped → **full session reload** (not in-place UI morph).                                                                                                                                                                                                                                |
| 7   | On switch-reload, **preserve map view + display layer + basemap + overlay toggles + opacity** via URL params; **reset the project area** (selection is mode-specific / can't round-trip a shapefile). **Confirmed.**                                                                                                                        |
| 8   | **Self-host** counties + towns on GeoServer (stable, fast; covered by existing GeoServer startup ping).                                                                                                                                                                                                                                     |
| 9   | **Do not self-host** parcels (too large, ~monthly batch updates) or protected open space (live ArcGIS).                                                                                                                                                                                                                                     |
| 10  | Independent **startup health checks** for parcels and POS, mirroring the existing GeoServer primary/fallback ping (lines 217–235 of `EcoAssess.app.R`). Graceful degradation: POS missing → disable one checkbox; parcels missing → fall back to draw/upload only (≈ regional behavior).                                                    |
| 11  | All external endpoint URLs are **named config constants**, not buried in helpers.                                                                                                                                                                                                                                                           |
| 12  | Multi-parcel selection treated like a multi-feature shapefile: dissolve into one project area. Bounding-box size limit applies; scattered/disjunct parcels that bust the bbox are out of scope (clear error message).                                                                                                                       |
| 13  | **Daily monitor**: GitHub Actions scheduled workflow checks GeoServer + parcels + POS + shinyapps.io, emails on failure. Separate deliverable, not app code; **after the app is in good shape**. Useful side effect: the morning ping warms the shinyapps.io instance, so the first real user each day skips the cold start. **Confirmed.** |

## `cfg` list (resolved at UI build from `request`)

- `cfg$regional` — TRUE/FALSE
- `cfg$title` — "EcoAssess" / "Massachusetts EcoAssess"
- `cfg$switch_label` / `cfg$switch_tooltip` — the "(i) switch" field text
- `cfg$boundary_label` — "Show states and counties" / "Show counties and towns"
- `cfg$boundary_layers` — GeoServer WMS layer list for `addBoundaries()`
- `cfg$show_parcels` — enable parcel UI + behavior
- `cfg$show_pos` — enable protected-open-space overlay
- `cfg$matomo_dimension` — per-mode analytics tag
- (data endpoint constants live separately, see Data sources)

## Workstreams / phases

1. **Expanded PoC** (next, see below). Resolves the parcel viewport-fetch +
   click-select interaction and the dedup strategy. Throwaway code.
2. **Mode infrastructure**: `ui <- function(request)`, `cfg` list, switch link
   with state-encoding URL params, Matomo dimension.
3. **Data layer**: config constants; startup checks for parcels + POS modeled
   on the GeoServer ping; graceful degradation paths.
4. **MA-mode UI deltas**: title; switch field + tooltip; `cfg$boundary_label`
   swap; "Show protected open space" checkbox; "Show parcel data" checkbox;
   "or [Select parcel(s)]" button under Draw/Upload.
5. **Parcel selection → project area**: assemble selected parcels into an sf
   object → `session$userData$poly`, `drawn = FALSE`. Existing `getReport`
   machinery (validate / transform / area limits / report) then applies
   unchanged.
6. **Overlays**: `addProtectedOpenSpace()` helper (filter `LEV_PROT == 'P'`);
   parametrize `addBoundaries()` by `cfg$boundary_layers`; prep + publish
   counties/towns layer on both GeoServers.
7. **Daily monitor**: GitHub Actions workflow.
8. **Tooltips** for every new control.
9. **Test + deploy** (single instance).

## Parcel display/selection design (from readMVT precedent)

Pattern lifted from `DEPMEP.app.R` + `readMVT::read.viewport.tiles`, minus MVT:

- New reactive: `observe({ if (isTRUE(input$map_zoom >= trigger)) { ...
  input$map_bounds ... } })`. The app currently has **no pan/zoom-driven
  fetch** — this is the one genuinely new reactive pattern.
- `trigger` zoom level: arbitrary to start, tuned empirically (PoC #2 in
  roadmap notes — sparse town fast at full extent, dense towns heavier).
- "Already-fetched" tracker in `session$userData` so panning fetches only new
  area (DEPMEP's `drawn` bit-matrix analog).
- `memoise` the ArcGIS fetch, **global** to share across users on the shared
  shinyapps.io session and throttle hits on the volatile ArcGIS endpoint.
- `groupOptions(..., zoomLevels=)` to hide parcels when zoomed out without
  discarding them.
- **New vs. DEPMEP**: DEPMEP only displays. Parcels need click-to-toggle
  selection (`input$map_shape_click`, per-parcel `layerId`), accumulation of
  selected geometries, visual distinction of selected vs. unselected, and
  final assembly into the project-area sf object.

## Open questions / to settle

- Q-A (decision 7) — **resolved 2026-05-15**: preserve view + display + basemap
  + overlay toggles + opacity; reset project area.
- Q-B (decision 13) — **resolved 2026-05-15**: GitHub Actions, deferred until
  the app is in good shape.
- PoC dedup — **largely resolved 2026-05-15** (PoC run 1): per-cell grid
  (one ESRI round-trip per cell) is **dead** — fetch is latency-bound, so it
  was unusably slow. Answer is a **smart hybrid**: cell ledger records only
  *coverage*; uncovered viewport → ONE fetch of the missing cells' strip
  (naive speed); revisiting covered ground → zero fetches (instant). PoC run 2
  to confirm it beats naive on realistic towns.
- **PoC open (run 2)**: pick `trigger` (BC leaning 15); confirm parcel ID
  field; judge smart-hybrid vs naive on realistic towns (Petersham default,
  not Cambridge — unrealistic); decide if box/lasso multi-select is wanted
  (shift-drag currently does nothing useful — see design note below).
- **Selection must be local.** Confirmed: re-fetching a clicked parcel from
  ESRI is unacceptably slow. Keep every fetched geometry in a per-session
  store; selection is an in-memory lookup. Carries into the real app design.

## Risks

- **ArcGIS endpoint volatility.** Parcels URL changed once (Oct→May) plus one
  red herring. Mitigated by config constants + startup check + graceful
  degradation + daily monitor. Residual risk: silent schema/field-name
  changes (already bit us once).
- **Dense-town performance** at the chosen `trigger` zoom — PoC must verify.
  Fetch latency is the dominant cost (instrumented in PoC). If render also
  bites in dense areas, `leafgl::addGlPolygons` (WebGL) is the scalability
  lever — noted, not yet needed.
- **CRS / datum correctness — elevated.** PoC shapefile export came out
  ~10 m N / ~30 m E. Proximate cause: `st_transform()` with the proj4 datum
  string `'+proj=longlat +datum=WGS84'` selects a different PROJ pipeline
  than EPSG:4326 under PROJ 6+/GDAL 3. **`get.shapefile.R:36` in the
  production regional app uses the same string** — latent offset risk there
  too (may be self-consistent within that app and thus unnoticed; needs a
  look, BC to judge). PoC now reports the source WKID to pin down the true
  ESRI SR. A 30 m parcel shift is unacceptable for the MA renewable-siting
  subsidy use case.
- **Scattered-parcel bbox limit** is a UX sharp edge (easy to click two far
  parcels); needs a clear, specific error message.

## Design notes / parked ideas

- **Box / lasso multi-select.** Clicking parcels one-by-one is fine for a
  few; selecting many adjacent parcels (common in conservation) wants a
  rubber-band box → `st_intersects`. Shift-drag is currently dead (boxZoom
  disabled). Candidate enhancement; prototype if BC wants it.

## Data sources

| Layer                   | Endpoint                                                                                                                | Notes                                                              |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Parcels                 | `https://services1.arcgis.com/hGdibHYSPO59RG1h/arcgis/rest/services/Massachusetts_Property_Tax_Parcels/FeatureServer/0` | tested 2026-05-12. Live ArcGIS. Field names changed once — verify. |
| Protected open space    | `https://arcgisserver.digital.mass.gov/arcgisserver/rest/services/AGOL/openspace/FeatureServer/0`                       | tested 2026-05-12. Filter `LEV_PROT == 'P'`. Live ArcGIS.          |
| Counties + towns        | Self-hosted WMS on both GeoServers                                                                                      | TODO: download, process, publish. Like regional states/counties.   |
| ecoConnect / IEI / etc. | Existing GeoServer (primary + fallback)                                                                                 | Unchanged.                                                         |

## Deferred / tracked (not planned yet)

- **shinyapps.io shutdown** end of 2026 → Posit Connect Cloud. No action until
  Posit ships the migration path.
- **Primary GeoServer subscription** ends ~2027-09 (~16 mo out) and is
  unreliable (down ~2 weeks as of 2026-05). Fallback is `marsh01` (UMass Win
  server, faster, but Patch-Tuesday reboots). BC pondering a fresh backup:
  `marsh02` (same rack, dodges Patch Tuesday) or a cheap always-on Linux box.
  See roadmap Extras. Tracked, not planned.
