# MA EcoAssess — Work Log

> Append-only, dated entries, newest at bottom. Companion: `dev/implementation-plan.md`.

## 2026-05-15

- **PoC URL breakage diagnosed & fixed.** `inst/scripts/MA_EcoAssess_proof_of_concept.R`
  stopped working: MassGIS moved/renamed the parcels feature service. Two
  issues found:
  
  1. `arc_select()` errored with "`x` must be a `FeatureLayer`..." — the new
     URL pointed at the `FeatureServer` root; needs `/0` for the layer.
  2. `filter_geom = bbox` passed a bare `st_bbox()` object; `arc_select()`
     wants an `sfc`. Fix: `st_as_sfc(bbox)`. (Worked before via lenient
     coercion in an older `arcgislayers`.) Kept the wrap even though current
     version tolerates the bbox.
  - Correct parcels endpoint settled (see plan, Data sources). Earlier
    `OpenSpaceLevProt` URL was a wrong turn (that's open space, not parcels).
  - Takeaway: ArcGIS endpoint volatility is a standing maintenance risk →
    drove decisions 10/11/13 (config constants, startup checks, daily monitor).

- **Planning rounds.** Settled architecture: single codebase + `regional` URL
  flag (default regional); `ui <- function(request)` + `cfg` list; single
  shinyapps.io instance; reload-on-switch preserving view (not project area);
  self-host towns/counties only; startup checks + graceful degradation for
  parcels & POS; multi-parcel = dissolved single project area with bbox limit;
  daily GitHub Actions monitor. Full table in `implementation-plan.md`.

- **Reviewed precedents** `DEPMEP.app.R` + `readMVT::read.viewport.tiles` —
  basis for the parcel viewport-fetch design (observe on `map_zoom`/
  `map_bounds`, already-fetched tracker, global memoise, `groupOptions`
  zoom-gating). New surface vs. DEPMEP: click-to-select + accumulate.

- **Created** `dev/implementation-plan.md` and this log.

- **Q-A / Q-B resolved.** Switch-reload preserves view/layers/toggles, resets
  project area. Monitor = GitHub Actions, deferred until app is solid (BC added
  it + a backup-GeoServer ponder to roadmap Extras; noted the morning-ping
  warm-up side effect). Doc ownership clarified: roadmap = BC's, plan + log =
  Claude-maintained.

- **Expanded PoC written**: `inst/scripts/MA_EcoAssess_poc2_parcel_select.R`.
  Viewport-fetch (observe on `map_zoom`/`map_bounds`), both dedup strategies
  behind `dedup_strategy` flag, global `memoise`, click-to-toggle selection,
  dissolve + dump-to-sf to prove the project-area hand-off. Defaults to a
  dense town (Cambridge) for the perf reality check.

- **PoC run 1 (BC) + iteration.** Findings:
  
  - Per-cell grid unusably slow (one ESRI round-trip per cell; fetch is
    latency-bound). Naive ok in light areas, laggy when dense. → reworked
    `grid` into a **smart hybrid**: cell ledger = coverage only; one fetch of
    the missing strip; instant on pan-back.
  - Selecting a parcel was unacceptably slow — click handler re-fetched the
    parcel from ESRI. → added per-session geometry **store**; selection is now
    a local lookup, no network.
  - Cambridge torture test unrealistic → default moved to Petersham; spectrum
    (Warwick/Concord/Cambridge) in comments. `trigger` 15 (BC), home_zoom 15.
  - Shift-drag "zoom" surprise = Leaflet `boxZoom` + dbl-click zoom → disabled
    both. Noted box/lasso multi-select as a parked design idea.
  - Added fetch / render / select instrumentation (live panel + console).
  - Shapefile offset ~10 m N / 30 m E: dump used proj4 datum string; switched
    to `st_transform(4326)`; added one-shot source-CRS report to ID the true
    ESRI SR. Flagged `get.shapefile.R:36` (same proj4 string) as latent risk.

- **Clobber + restore.** A stale RStudio save overwrote the rev-2 edits
  (lost: smart-hybrid grid, local-store selection, instrumentation,
  boxZoom/dbl-click disable, proj4→EPSG, CRS report). Also introduced a
  syntax bug (`home < c(...)` instead of `<-`). Restored via full rewrite
  (rev 2), keeping BC's intentional choices: Warwick home, `trigger` 15,
  `dedup_strategy` 'naive'. Added an in-file note to close the PoC in RStudio
  while Claude edits.

- **Facts confirmed.** `LOC_ID` is unique, string form `M_133746_940936`
  (where-clause quoting already correct). CRS: Leaflet renders 3857;
  `addPolygons` wants 4326 (display path correct); MassGIS native expected
  EPSG:26986 (NAD83 SP) — NAD83→WGS84 in MA is ~1 m, so the ~30 m offset
  points at the proj4 datum string, not the source SR. CRS report now prints
  source WKID + sample coord before/after transform to confirm.

- **PoC run 2 (BC).** Results:
  
  - Smart-hybrid grid validated: Petersham first ~580–660 ms (naive ~640,
    one slow-fetch run 2960 ms); Concord ~1000 ms; **grid revisit
    near-instant**. Grid is the approach; naive kept as baseline only.
  - Instrumentation overturned the fetch-only assumption: **Concord render
    ~2140 ms** > fetch ~1000 ms. → `leafgl` elevated to a planned lever.
    ESRI fetch high-variance (2960 ms outlier).
  - Selection **instant** (local store works). BC: selection latency matters
    more than display latency — design constraint.
  - Offset: proj4→EPSG fix removed 30 m E, halved N (~10 → ~5 m N). `=== SOURCE
    CRS ===` block didn't print — it was inside the memoised fetch; warm cache
    skipped it. → moved to an un-memoised **startup probe** (prints every
    launch). Residual ~5 m N still to explain next session.
  - Box-select: **not needed now** (BC) — click-to-toggle is enough; parked.
  - Standing instruction: **commits not signed** (no Co-Authored-By trailer).

- **Checkpoint commit** (no sign-off, not pushed) — end of week.

- **Next**: BC reruns, reads the startup `=== SOURCE CRS ===` block; we settle
  the ~5 m residual (datum vs ArcGIS quantization vs comparison artifact),
  then move toward real-app work (mode infra / `cfg`).

## 2026-05-20

- **Source CRS confirmed EPSG:26986** (NAD83 MA SP) from the startup probe.
  ~5 m N residual diagnosed as the WGS84 round-trip artifact (sf's NAD83→WGS84
  + ArcGIS's WGS84→NAD83 don't exactly invert; plus NAD83(2011)/WGS84
  realization gap). Not our bug — but avoidable by not round-tripping.
- **CRS fixes on `main`**: replaced proj4 datum string with EPSG:4326 in
  `get.shapefile.R`, dropped `type='proj'` from the 3857 transform in
  `EcoAssess.app.R`. BC ran 2+ standard test shapefiles (MA State Plane and
  NAD83) through deployed vs revised — **identical report results** (sub-pixel
  for 30 m rasters). Folded in version bump 1.1.2 → 1.1.3, header cleanup,
  and a whatsnew entry; deployed as v1.1.3.
- **Cherry-picked onto Massachusetts** as `b58219e` so branches stay in sync.
- **PoC refactor (change #1)**: parcels now stay in native CRS throughout —
  `fetch_bbox` returns native, `store` holds native, `selected` holds native;
  `addPolygons` transforms to 4326 inline. **Dump exports in 26986** for
  exact overlay with MassGIS authoritative. `st_area` runs on 26986 directly.
  Dropped the `if(!exists())` guard on `fetch_bbox_C` so dev re-sources can't
  inherit a stale 4326 cache.
- **Plan updated**: CRS source-WKID resolved; CRS-correctness risk closed;
  real-app contract recorded — parcels populate `poly.proj` directly via
  26986→3857 (no 4326 detour), `poly` via 26986→4326 for area + display.
- **Native-CRS dump verified**: BC overlaid the 26986 dump against MassGIS
  authoritative in ArcGIS — exact alignment. CRS chapter genuinely closed.
- **New bug found**: `st_union` throws `TopologyException: unable to assign
  free hole to a shell` on certain 2-parcel combinations where a road
  bisects one of them. Diagnosed as the well-known MassGIS sliver-along-
  shared-boundary issue. Fix: `st_make_valid` + `st_union` with a
  `st_buffer(., 0)` fallback. Applied to PoC dump and recorded in the
  plan as required behavior at the real-app union point.
- **Next**: BC retries the problem combination with the fix; if clean, on
  to real-app mode infrastructure (`ui <- function(request)`, `cfg` list).
- **Sliver cause narrowed**: BC re-selected the same 2 parcels from the
  authoritative MassGIS layer in ArcGIS Desktop, exported a shapefile, and
  ran it through the production app — succeeded cleanly through both
  `st_union` (in `get.shapefile.R`) and `st_make_valid` (in `getReport`).
  → The slivers are an artifact of ArcGIS REST geometry quantization, not
  inherent to MassGIS data. BC further confirmed with an inclusive sweep-
  select-then-trim from the authoritative layer (any latent slivers in the
  source would have been captured): still clean. PoC's defensive recipe is
  in the right place. Worth a future spike to see if `arc_select` can
  request un-quantized geometry and eliminate the issue at source.
- **Workstream 2 scaffold (mode infrastructure)**: extracted three new files
  — `resolve.cfg.R` (URL query → cfg list), `switch.url.R` (URL flipper,
  not yet wired in UI), `make.ui.R` (entire UI tree as a function of cfg).
  `EcoAssess.app.R` now reads as `ui <- function(request) make.ui(...)` and
  the server stashes the same cfg in `session$userData$cfg`. Default URL =
  bit-perfect regional (only the page title sources from cfg in WS2; rest
  of the UI deltas come in WS 4). Smoke test: open at `?regional=false` and
  the title should read "Massachusetts EcoAssess"; otherwise identical.
- **Hit a closure-scope gotcha**: `make.ui()` couldn't find `tipped()` even
  though `tipped` is defined at top of `EcoAssess.app.R`. Cause: when RStudio
  (or `runApp`) sources `app.R` into a session-isolated app environment,
  top-level defs land there — but `source('make.ui.R')` with default
  `local = FALSE` puts `make.ui` in `globalenv()` instead, so its closure
  doesn't see the app-env tipped/tooltips/layers. Fix: `source(..., local =
  TRUE)` on `make.ui.R` only (the other two new files don't reference
  app-locals). Existing self-contained helpers (`get.shapefile`, `draw.poly`,
  etc.) didn't hit this — they reference only base + library symbols.

## 2026-05-21

- **Discussed packaging vs. R/ autoload vs. status quo.** BC chose Option 2
  (Shiny's `R/` autoloader — convention, not a real package). Did the
  initial move of helpers into `R/` and deleted the source block — and hit
  the closure issue again because `tipped` (and tooltips, layers, etc.)
  were still inline in `app.R`. The closure chain from `R/`'s autoload env
  doesn't reach app.R's top-level env: siblings, not parent/child.
- **Resolved by finishing the move.** Pulled all remaining app-level state
  out of `app.R` into `R/`:
  - `R/tipped.R` — the `tipped()` helper
  - `R/app.data.R` — `home`, `zoom`, `layers`, `full.layer.names`,
    `geoserver`, `osm_email`
  - `R/load.tooltips.R` — all 12 tooltip + 4 About `includeMarkdown` loads
  - `R/make.server.R` — entire server body as `make.server(input, output,
    session)` (body byte-identical to the prior inline version)
  - `app.R` trimmed to ~46 lines: libraries + `plan()` + `ui <-
    function(request) make.ui(resolve.cfg(...))` + `server <- make.server`
    + `shinyApp(ui, server)`.
- **Closure issue structurally gone.** Everything any helper might need is
  in the autoloaded `R/` env; `ui` and `server` see it via Shiny's
  re-parenting. Future helpers added during WS 4 drop into `R/` and just
  work — no `local = TRUE` boilerplate needed ever again.
- **`extra_functions/`**: BC moved the not-currently-sourced top-level
  files (addPADUS, compare_percentiles, loadlibs, make.style, etc.) out
  of the way so `R/` autoload doesn't pick them up. Kept under version
  control for now in case anything's needed later.
- **Next**: BC smoke-tests the refactored app on Massachusetts (default URL
  + `?regional=false`); if clean, cherry-pick the same refactor to `main`
  for deployment, then on to WS 4 (switch field, boundary label, parcel
  + POS UI controls, etc.).
- **Next**: BC re-runs and smoke-tests this; if the regional default still
  looks right and `?regional=false` flips the title, on to WS 4 (switch
  field, boundary label, parcel + POS UI controls).

## 2026-05-22

- **Fixed two refactor follow-on bugs.** `server <- make.server` (bare alias)
  swapped for a `function(input, output, session)` wrapper — the alias tripped
  Shiny's session-output wiring and the Get-report downloadHandler 404'd.
  Also dropped a now-broken `source('annotation-scale.R')` inside
  `make.report.maps.R` (the file is autoloaded from `R/` now). Report flow
  verified working end to end.
- **WS 4 — MA-mode UI shell built.** Decisions (via AskUserQuestion): switch
  field goes in the left sidebar above Version; compact wording ("Regional
  EcoAssess (i) switch"). Built:
  - `resolve.cfg` expanded: `regional`, `title`, `switch.label`,
    `boundary.label`. MA-only gating stays as `!regional` (no redundant
    cfg fields).
  - `make.ui`: switch field (both modes, wired to `switch.url` — basic
    flag-flip, no state encoding yet); MA-only "Show protected open space"
    + "Show parcel data" checkboxes; MA-only "or Select parcel(s)" button;
    `boundary.label` swap on the show-boundaries checkbox.
  - 5 new tooltips: `tooltipRegionalVersion`, `tooltipMassachusettsVersion`
    (text verbatim from roadmap), plus `tooltipShowPOS`, `tooltipShowParcels`,
    `tooltipSelectParcels` (first-draft wording — BC to review).
  - New controls are inert — `show.pos` / `show.parcels` / `selectParcels`
    have no server handlers yet; that's WS 5/6.
- **Note**: in MA mode the boundary checkbox now reads "Show counties and
  towns" but still draws the regional states+counties WMS until the
  counties/towns layer is published to GeoServer (WS 6).
- **WS 5 started — increment 5a (parcel display).** Design fork settled (via
  AskUserQuestion): displayed parcels are a passive overlay; clicking selects
  only after Select parcel(s) is pressed. Built:
  - `app.data.R` — `parcels.url`, `parcels.id` (`LOC_ID`), `parcels.zoom`
    (15), `parcels.grid` (0.01°), `parcels.debounce` (300 ms) constants.
  - `R/get.parcels.R` — `parcels.layer()` lazy process-global handle
    (one `arc_open`, NULL on failure, regional mode never calls it);
    `get.parcels()` viewport fetch returning native EPSG:26986, memoised
    globally as `get.parcels.C`; grid helpers `parcel.cells` /
    `parcel.cell.key`. arcgislayers + memoise referenced via `::` so they
    load on demand — no `library()` call, no autoload-timing risk.
  - `R/parcel.server.R` — `parcel.server(input, output, session)`, a
    self-contained MA-parcels module. 5a: the viewport-display observer
    (smart-hybrid grid, zoom-gated on `parcels.zoom`, gated on the
    `show.parcels` checkbox). Stashes native geoms in `parcel.store` for 5b.
  - `make.server.R` — MA mode calls `parcel.server`; if `parcels.layer()`
    is NULL the parcels endpoint is down → disable show.parcels +
    selectParcels (decision 10 graceful degradation; user-facing error
    modal still a TODO — only a console message for now).
- **Note**: parcels show only at zoom 15-16 (app `maxZoom` is 16). If that
  band is too tight, options are lower `parcels.zoom` or raise `maxZoom` —
  but USGS basemaps top out near 16, so raising it degrades those tiles.
  Tuning call for BC after test-driving.
- **5a verified** by BC — parcel display works well. Checkbox-spacing CSS
  re-scoped to `:has(.checkbox)` so it no longer squeezes the Full screen
  `materialSwitch`; BC tuned the margin to -0.75rem.
- **Mode-specific home + switch view-preservation (decision 7) — built.**
  - `app.data.R`: `home.regional`/`zoom.regional` (c(-75,42), 6) and
    `home.ma`/`zoom.ma` (c(-72.0546, 41.5818), 7). MA home dialed in with a
    temporary console monitor (since removed); zoom 7 — zoom 8 clips the
    state at common screen sizes.
  - `resolve.cfg`: now also returns `home.zoom` (mode overview zoom) and
    `view` = list(lng,lat,zoom). `view` is the mode home unless the URL
    carries valid lng/lat/zoom params, in which case the carried view wins.
  - `switch.url`: gained a `view` arg — appends `&lng=&lat=&zoom=` when a
    view is carried, bare `?regional=...` otherwise.
  - `make.ui`: switch is now an `actionLink('switch.mode')` instead of a
    static `<a href>`.
  - `make.server`: `renderLeaflet` opens at `cfg$view`; new
    `observeEvent(input$switch.mode)` — if the user has zoomed in past the
    mode's overview zoom it carries the current view (center from
    `map_bounds`, zoom from `map_zoom`), else lands on the other version's
    home; navigates via `shinyjs::runjs`. Temp monitor removed.
  - Carry heuristic: `input$map_zoom > cfg$home.zoom`. Zoomed in = looking
    at something specific = carry; at the overview = reset to the other
    version's home (avoids dumping a useless panned overview into the other
    mode).
- **Switch view-preservation verified** by BC, who then noted the switch
  resets layer/opacity/basemap — the rest of decision 7.
- **Decision 7 completed** — the switch now carries control state too:
  - `switch.url`: generalized to take a `carry` named list; URL-encodes
    values, drops NULL/empty entries.
  - `make.server` switch observer: builds `carry` with layer (from
    `session$userData$show.layer`), ecoConnect display, basemap, opacity,
    show-boundaries — always — plus lng/lat/zoom when zoomed in past the
    overview.
  - `resolve.cfg`: parses `layer` / `display` / `basemap` / `opacity` /
    `boundaries` back out (NULL when absent).
  - `make.ui`: each control's initial value comes from cfg when carried,
    else its default; carried `layer`/`display`/`basemap` are validated
    against their choice sets.
  - `make.server`: a carried "layers off" (`cfg$layer == 'none'`) is
    restored explicitly (presets `show.layer`, disables the display/opacity
    sliders) since no layer-radio observer fires to do it.
  - Deliberately NOT carried: "Show user basemap" (needs an upload that
    can't round-trip a reload) and the MA-only POS/parcel toggles (the
    switch always flips the mode, so there's no same-mode target).
- **Plan cfg-list collision** — an editing collision (a stale MarkText buffer,
  not RStudio, saved over the file) had dropped the `cfg$home.zoom`/`cfg$view`
  bullets while keeping BC's new WS #11. Recovered: bullets restored, cfg
  section completed to all 11 fields, WS #11 kept. BC will keep MarkText
  closed during Claude work and fresh-load before editing.
- **Full switch verified** by BC.

- **WS 5b + 5c — parcel selection → project area (complete).** They merged
  into one increment: dissolving the selection on every click keeps
  `session$userData$poly` current, so getReport consumes it through its
  existing uploaded-shapefile path with **no `make.server` change** — all
  logic is in `parcel.server`.
  - `selectParcels` observer: enters selection mode — `selecting <- TRUE`,
    turns `show.parcels` on and locks it, disables Draw/Upload/selectParcels,
    enables Restart (mutual exclusion, like the Draw tools).
  - `map_shape_click` observer: only acts in selection mode (passive display
    ignores clicks, per the design fork); toggles the clicked parcel via the
    PoC's base-id / `sel_`-prefix scheme; geometry comes from `parcel.store`.
  - `refresh.selection`: redraws the purple highlight group and dissolves the
    selection (st_make_valid + st_union + buffer-0 fallback) into
    `session$userData$poly` (4326), `drawn = FALSE`; toggles getReport.
  - `observeEvent(drawPolys / shapefile)`: disable selectParcels (mutual
    exclusion, other direction). Restart observer clears the selection and
    leaves selection mode.
  - getReport: untouched — `drawn = FALSE` + `poly` set means its existing
    else-branch runs the report on the dissolved parcels; area limits etc.
    apply automatically (decision 12).
- **Parcel fetch crash — diagnosed as an ESRI endpoint outage.** First run
  of parcel display crashed in `arcgislayers::arc_select` → `arcpbf`
  ("subscript out of bounds"). Diagnosis:
  - PoC #2 (known-good) failed identically → not our code.
  - BC had been panning parcels successfully ~2 h earlier with the *same*
    package versions (httr2 1.2.2, arcgislayers 0.6.0, arcgisutils 0.5.0,
    arcpbf 0.2.0), no updates since → not a package regression.
  - Requests hang "an extraordinarily long time"; the error varies by httr2
    version (subscript-out-of-bounds on 1.2.2, can't-determine-count on
    1.2.1) — same root, different `arc_select` stage. → the MassGIS
    `Massachusetts_Property_Tax_Parcels` FeatureServer is degraded right now
    (transient outage, or throttling after BC's burst of pan-queries).
  - Committed `1caea5d`: `tryCatch` around the fetch + bbox/zoom/count
    logging — the app degrades instead of crashing.
- **WS 5 status**: parcel selection is **code-complete** and was working
  ~2 h ago — the code is sound; just untestable until the endpoint recovers.
- **Robustness gaps this exposed (next focused task):**
  1. MA mode **hangs at startup** when the endpoint is slow — the
     `make.server` parcels startup-check calls `arc_open`, which blocks the
     whole session. Make that probe non-blocking / time-limited; draw/upload
     don't need parcels.
  2. The fetch should **time out fast** (~15 s) and degrade, not spin.
  3. The daily monitor (WS 8) would have flagged this — value now concrete.
- httr2 was rolled back to 1.2.1 mid-diagnosis (wrong lead) → restore 1.2.2.
- **WS 5 VERIFIED end to end (2026-05-22).** The ESRI endpoint recovered
  (the `?f=json` browser call returned the layer description). BC reinstalled
  current httr2 (1.2.2), restarted RStudio, ran the real app, selected
  parcels, generated a report — the full parcel path works. Outage cause
  stays ambiguous: ESRI transient/throttle, or a compromised R session.
  Diagnostic kit for next time: run PoC #2 from a UMass server (different IP
  → isolates rate-limiting), the `?f=json` call (server up?), restart
  R / RStudio (session poisoned?).
- **Next**: the robustness pass (non-blocking startup probe + fast fetch
  timeout — make ESRI hiccups a shrug, not a hang); then WS 6 (POS overlay +
  boundary swap, counties/towns layer is on GeoServer), WS 8 (daily monitor),
  and BC's WS 7 (About page) / WS 11 (AcuGIS counties/towns).

## 2026-05-27

- **Switched to CLI Claude Code** (API key) from Desktop Claude Code (Pro account) to manage token costs after a heavy previous session.
- **Robustness pass — ESRI startup probe (complete).** Replaced the blocking `parcels.layer()` / `arc_open` startup check with `esri.probe()`, which pings both the parcels and POS FeatureServer endpoints using `httr::GET` with explicit timeouts (same pattern as the GeoServer probe). Parcels gets 6 s; POS gets 6 s if parcels responded or 2 s if parcels already failed (outage confirmed, no need to linger). If either is unreachable: `error.message('ESRI')` shows a modal, `show.parcels` and `selectParcels` are disabled, session falls back to draw/upload — mirrors the GeoServer outage path exactly.
- **Mid-session fetch timeout** — decided not to add one. `arc_select`'s `...` pass into the ESRI query params, not the httr2 request, so there's no clean injection point. On Windows, `setTimeLimit(elapsed=)` doesn't reliably interrupt C-level I/O. The `tryCatch` in `parcel.server` already handles error responses; a true silent hang (server accepts connection but never replies) is a narrow edge case acceptable given the startup probe covers the main outage scenario.
- `pos.url` added to `app.data.R` now (needed by the probe; also ready for WS 6).
- `inst/errorESRI.md` stub created; BC to fill in final text.
- **Next**: WS 6 — POS overlay + boundary swap to counties/towns. Confirm towns layer name (`mass_towns` vs `mass_tow`) with BC before wiring.

## 2026-05-28

- **WS 6 — POS overlay + boundary swap (complete).** BC confirmed towns layer is `boundaries:mass_towns`. Built viewport-driven POS overlay using the same smart-hybrid grid pattern as parcels, with coarser `pos.grid = 0.1°` (vs parcels' 0.01°) to match the lower zoom at which open space parcels appear useful.
  - `app.data.R` — added `pos.url` (MassGIS openspace FeatureServer/0), `pos.zoom = 12`, `pos.grid = 0.1`, `pos.debounce = 300`.
  - `R/get.pos.R` — `pos.layer()` lazy process-global handle; `get.pos(xmin, ymin, xmax, ymax)` bbox-parameterized fetch with `where = "LEV_PROT = 'P'"` (permanently protected only, BC confirmed LEV_PROT is a character string), `suppressMessages` around `arc_select` to swallow cli "Iterating..." toasts; `get.pos.C` memoised globally; grid helpers `pos.cells` / `pos.cell.key`.
  - `R/pos.server.R` — `pos.server(input, output, session)`, coverage ledger in `session$userData$pos.fetched`. `addPolygons` uses `color = '#00DD00'`, `weight = 5`, `opacity = 1`, `fillOpacity = 0.10`, `pane = 'pos-pane'`. BC iterated on color/weight/opacity interactively.
  - `R/addBoundaries.R` — added `layers` parameter; regional passes `boundaries:states,boundaries:counties`, MA passes `boundaries:mass_towns,boundaries:mass_counties`.
  - `resolve.cfg.R` — added `boundary.layers` field to cfg list.
  - `make.server.R` — `pos.server()` called alongside `parcel.server()`; `addMapPane('pos-pane', zIndex = 410)` and `addMapPane('parcels-pane', zIndex = 420)` in `renderLeaflet` MA branch (guarantees z-order regardless of toggle sequence); `addBoundaries` now receives `cfg$boundary.layers`.
  - `parcel.server.R` — both `addPolygons` calls (display + selection highlight) gained `pathOptions(pane = 'parcels-pane')`.
  - Disable path on ESRI outage updated to include `shinyjs::disable('show.pos')` (initially missed; BC caught it).
- **Initial POS approach (statewide fetch) rejected.** First attempt fetched all POS state-wide at startup: 1m17s initial load, 32s to redraw on toggle. Massachusetts has 51,745 protected-land parcels. Reverted immediately; rewrote to viewport-driven.
- **Layer z-order issue.** POS sometimes rendered above parcels when toggled in certain sequences. Fixed with Leaflet panes created at map init — deterministic order regardless of draw sequence.
- **Stroke opacity artifact.** Shared parcel/POS borders appeared darker (stroke stacking). Fixed by setting `opacity = 1` in all `addPolygons` calls (not the default 0.5).
- **"Iterating..." toast.** arcgislayers cli messages routing through Shiny's message handler caused unsightly toasts. Suppressed with `suppressMessages()` around `arc_select`.
- **Primary GeoServer outage.** Counties/towns didn't show because the primary GeoServer had been down for 3+ weeks; layers were on marsh01 (fallback) only. BC brought the primary back up and deployed the layers there — no code change needed.
- **Duplicate `view = view,` in resolve.cfg.R.** BC's edit introduced a duplicate key. Fixed.
- **Zoom monitor** added temporarily (to pick `pos.zoom = 12`) then removed once the zoom level was settled.
- **BC edits in `make.ui.R`**: checkbox labels changed from "Show protected open space" / "Show parcel data" / "Show user basemap" to "Protected open space" / "Parcel boundaries" / "User basemap" (dropped redundant "Show").
- **WS 7 — About page fork (complete).** `aboutTool.md` was a single document serving both modes. Forked it into `inst/aboutRegional.md` and `inst/aboutMassachusetts.md` (both copied from `aboutTool.md` as the starting point). `load.tooltips.R` updated to load both; `make.server.R` `aboutTool` observer now picks `aboutRegional` vs `aboutMassachusetts` by `cfg$regional`, with version-specific modal title suffix ("(regional version)" / "(Massachusetts version)"). BC edited `aboutMassachusetts.md` to final form. `aboutTool.md` left in place, orphaned.
- **WS 8 — GitHub Actions health monitor (complete).** `.github/workflows/health-monitor.yml` pings 5 endpoints with `curl -L --max-time 15`: GeoServer primary, GeoServer fallback, MassGIS parcels, MassGIS POS, EcoAssess shinyapps.io. Fails the job (GitHub emails repo owner) if any return non-200. Schedule: daily noon UTC (7 AM EST / 8 AM EDT); `workflow_dispatch` for manual trigger. Endpoint list matches what `esri.probe()` and the GeoServer probe already check at app startup, plus the app itself. **Note**: scheduled workflows and `workflow_dispatch` only fire from the default branch (`main`). Workflow was committed on `Massachusetts` (commit `7fd7ab4`) and cherry-picked to `main` as `86a4ee6`. BC must push `main`, then the workflow appears in GitHub Actions → EcoAssess Health Monitor → Run workflow for manual testing.
- **Next**: push `main` (BC to ask explicitly), trigger workflow_dispatch to verify; then final QA of the MA app before a draft release.
