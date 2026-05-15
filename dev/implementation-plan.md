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
- PoC dedup — **RESOLVED 2026-05-15** (run 2). **Smart-hybrid grid is the
  approach.** Run-2 numbers: Petersham first ~580–660 ms (naive ~640, but
  2960 ms on a slow-fetch run); Concord ~1000 ms; grid revisit near-instant.
  Comparable to naive on first visit, far better on revisit, no downside.
  Naive kept only as a comparison baseline. `trigger` = 15.
- **Selection must be local.** Confirmed: in-memory store → selection is
  instant. BC's UX point: selection latency matters *more* than display
  latency (users expect an immediate click response). Design constraint.
- **CRS source WKID — still open.** proj4→EPSG fix removed the 30 m E and
  halved the N error (~10 m → ~5 m N). One-shot CRS report didn't fire (lived
  inside the memoised fetch; warm cache skipped it) → moved to an un-memoised
  startup probe. Next session: read the printed source WKID to settle whether
  the ~5 m residual is NAD83/WGS84 (~1–2 m) + ArcGIS quantization, or partly
  an artifact of BC's 4326-vs-26986 comparison (which itself reprojects).

## Risks

- **ArcGIS endpoint volatility.** Parcels URL changed once (Oct→May) plus one
  red herring. Mitigated by config constants + startup check + graceful
  degradation + daily monitor. Residual risk: silent schema/field-name
  changes (already bit us once).
- **Dense-town render cost — confirmed real.** Run-2 instrumentation
  overturned the fetch-only assumption: Concord render was ~2140 ms while
  fetch was ~1000 ms. `leafgl::addGlPolygons` (WebGL) is now a **planned
  optimization lever for the real app**, not just a noted one. ESRI fetch
  also has high variance (one Petersham run 2960 ms) — argues for the grid
  cache + the daily warm-up ping.
- **CRS / datum correctness — improved, not closed.** Original ~10 m N /
  ~30 m E. proj4 datum string `'+proj=longlat +datum=WGS84'` vs EPSG:4326
  under PROJ 6+/GDAL 3 was the main culprit: EPSG fix removed the 30 m E and
  halved N to ~5 m. Residual ~5 m N still under investigation (see CRS source
  WKID item under Open questions). **`get.shapefile.R:36` in the production
  regional app uses the same proj4 string** — latent offset risk there too
  (may be self-consistent and unnoticed; BC to judge whether worth a look). A
  multi-metre parcel shift is unacceptable for the MA renewable-siting
  subsidy use case, so the residual must be explained before real-app work.
- **Scattered-parcel bbox limit** is a UX sharp edge (easy to click two far
  parcels); needs a clear, specific error message.

## Design notes / parked ideas

- **Box / lasso multi-select** — **parked 2026-05-15** (BC's call):
  click-to-toggle is enough; users expect to pick only a handful of parcels.
  Shift-drag is free (boxZoom disabled) if revisited. Easy to add later via
  rubber-band box → `st_intersects`.

## Process conventions

- Roadmap is BC-owned; this plan + work log are Claude-maintained (BC may
  edit). Keep them current each session.
- **Commits: no sign-off / no `Co-Authored-By` trailer.** Commit (do **not**
  push) as an end-of-session safety net — guards against RStudio-save
  clobbering. Match the repo's terse message style.

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
