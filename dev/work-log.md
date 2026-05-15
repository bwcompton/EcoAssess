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
