# CLAUDE.md — agent context for EcoAssess (Massachusetts extension)

> **Project state lives elsewhere — read these first.**
> - `dev/implementation-plan.md` — architecture decisions, the `cfg` list, workstreams.
> - `dev/work-log.md` — dated chronological record, every session.
> - `C:\Work\etc\Obsidian\MA EcoAssess roadmap.md` — BC-owned, not in repo; kept current for the agent to read. **Re-read at session start.**

## Working with Brad

R expert at UMass DSL; conservation / spatial-ecology background. Be direct; he knows R. Established interaction pattern:

- **Discuss before non-trivial changes.** Surface real design forks; build after consent. Trivial / mechanical changes are fine to just do.
- **Concise responses** — no fluff, no over-explaining. He's iterating fast.
- **Hands-on** — he tunes values, makes cosmetic edits, will ask focused questions.

## Project at a glance

Single-codebase Shiny app. Mode selected by URL: `?regional=true` (default) or `?regional=false` (Massachusetts version).

- **Regional** — 13 Northeast states; deployed on shinyapps.io from `main`.
- **Massachusetts** — adds MassGIS parcels as a third project-area method (alongside Draw and Upload), MA counties/towns boundaries, and a protected-open-space overlay. Funded by MA Div. of Conservation Services. Dev on the `Massachusetts` branch.

Users: local land trusts (often no GIS), state/federal agencies, NGOs (TNC), consultants. **MA mandates use of this in renewable-siting subsidy decisions** — so CRS precision and reliability matter materially.

## Repo layout

- `EcoAssess.app.R` — minimal entry point (~46 lines): libraries + `ui` (function of request) + `server` (function wrapper around `make.server`) + `shinyApp`.
- `R/` — Shiny auto-loads every `.R` here at startup. Helpers, app data (`app.data.R`), tooltip loads (`load.tooltips.R`), `make.ui`, `make.server`, `resolve.cfg`, `switch.url`, `parcel.server`, `get.parcels`, plus the existing report machinery.
- `inst/` — tooltip + About markdown, JS, CSS; `inst/scripts/` holds the PoCs.
- `dev/` — the two living docs.
- `extra_functions/` — archived `.R` not autoloaded.
- `www/` — static assets including gitignored API-key files.

## Code style (house)

- Quoted function names: `'make.ui' <- function(cfg) {...}`.
- Dot-separated names (`make.ui`, not `make_ui`; `cfg$switch.label`).
- 3-space indent.
- Comment header per function — name, purpose, Arguments, Result, `B. Compton, <date>`.
- One function per file when reasonable.
- **Trailing commas in Shiny tag function calls are intentional** (htmltools tolerates them) — do not "clean them up."
- `sf::`, `terra::`, `arcgislayers::`, `memoise::` are usually qualified; `shiny`, `leaflet`, `shinyjs` mostly aren't. Match what's around.

## Commit conventions

- **No sign-off, no `Co-Authored-By` trailer.**
- **No hard line breaks in commit message bodies** — BC reads via RStudio and GitHub, both of which wrap. Subject line short and imperative; body paragraphs one long line each; blank lines between paragraphs and before bullet lists.
- Commit promptly as an end-of-session safety net. **Never push** unless BC explicitly asks. A committed file is recoverable from any clobber via `git checkout <file>`.
- Match the repo's terse, sentence-style.
- When staging, add specific files by name (not `git add -A` / `git add .`) — `www/` holds API keys.

## Branches

- `main` — deployed regional app on shinyapps.io. v1.1.3 is live.
- `Massachusetts` — dev for the MA extension. All current work happens here.
- CRS/EPSG fixes were cherry-picked to `main` after BC verified them against standard test shapefiles; that's the pattern when something should ship to regional too. Otherwise keep work on `Massachusetts`.

## Doc ownership and editing collisions

`dev/implementation-plan.md` and `dev/work-log.md` are **Claude-maintained, BC may edit**. The roadmap (Obsidian) is BC's. When BC has these open in **MarkText** or RStudio, a stale-buffer save can clobber agent edits silently. Mitigation:

- Ask BC to keep those editors closed while the agent is working, and fresh-load before editing.
- Always re-read the file (or `git diff`) before editing if anything looks off — never trust your in-memory copy after a gap.
- A clobber is recoverable: `git checkout <file>` restores the last commit's version.

## Gotchas already mastered — don't relearn these

- **Shiny `R/` autoload puts files in the app env.** That's why *everything* lives in `R/` — in-app helpers see each other without `source(..., local=TRUE)` boilerplate, and `make.ui` / `make.server` can reach top-level state.
- **`server` is a function wrapper, not a bare alias.** `server <- function(input, output, session) make.server(input, output, session)`. A bare `server <- make.server` tripped Shiny's session-output wiring and 404'd `downloadHandler`s.
- **`isolate(resolve.cfg(session$clientData$url_search))`** at server start — `url_search` is a reactive value; reading it outside a reactive context errors.
- **Use EPSG codes, not proj4 datum strings.** `st_transform(x, 4326)`, never `st_transform(x, '+proj=longlat +datum=WGS84')`. Under PROJ 6+/GDAL 3 the proj4 string can pick a null datum shift and introduce a multi-metre offset. Caught and fixed across the regional + MA paths.
- **CRS contract for parcels**: native EPSG:26986 throughout the parcel path; `st_transform` to 4326 only at `addPolygons`. `session$userData$poly` is 4326 (matching the upload path); `getReport` then does 4326→3857 — a harmless detour with EPSG codes everywhere.
- **MassGIS parcels carry sub-mm slivers along shared boundaries.** `st_union` can throw `TopologyException: unable to assign free hole to a shell`. Recipe: `st_make_valid()` then `st_union()` with `st_buffer(., 0)` fallback. Lives in `parcel.server`'s `refresh.selection`.
- **CSS `:has(.checkbox)`** targets only Shiny `checkboxInput` markup, not the Full screen `materialSwitch` (which is also a checkbox underneath). That selector is what scopes the spacing rule.
- **`arc_select` / `arcpbf` are fragile.** A 2026-05-22 outage produced `Error in [[: subscript out of bounds` in `arcpbf::post_process_list`. It was an **ESRI endpoint problem**, not our code (PoC #2 failed identically; same package versions had worked two hours earlier). Diagnostic kit for next time:
  1. Run `inst/scripts/MA_EcoAssess_poc2_parcel_select.R` from a **UMass server** (different IP → isolates rate-limiting).
  2. Hit `<FeatureServer>/0?f=json` in a browser (server up?).
  3. Restart R / RStudio (session poisoned?).
- **The cfg section in `dev/implementation-plan.md`** has been the site of editing collisions twice. Re-read before editing it.

## Reference points

- **PoC #2** at `inst/scripts/MA_EcoAssess_poc2_parcel_select.R` is the proven reference for parcel viewport-fetch + click-select mechanics. If real-app behavior diverges, compare against this — it's the known-good baseline.
- **The `cfg` list** (in `resolve.cfg`) is the single source of every mode difference. Eleven fields, documented in the plan. Don't add redundant cfg fields — `make.ui` uses a local `ma <- !cfg$regional` for MA-only UI gating.

## Open at the time of this handoff (2026-05-28)

All major workstreams are complete. App is in draft-release shape.

**Completed this session (2026-05-28):**
- **Robustness pass** — `esri.probe()` replaces the blocking `arc_open` startup check; pings both MassGIS endpoints with short timeouts; ESRI outage → modal + graceful degradation. Done.
- **WS 6** — POS overlay (viewport-driven, coarse grid, pane z-order) + boundary swap to `boundaries:mass_towns` / `boundaries:mass_counties` via `cfg$boundary.layers`. Done.
- **WS 7** — About page forked into `aboutRegional.md` / `aboutMassachusetts.md`; modal title says which version. BC edited the MA text. Done.
- **WS 8** — `.github/workflows/health-monitor.yml` pings 5 endpoints daily at noon UTC; `workflow_dispatch` for manual trigger. Cherry-picked to `main` as `86a4ee6`. **Pending BC**: push `main`, then trigger manually via Actions → EcoAssess Health Monitor → Run workflow.

**Remaining:**
1. **BC to push `main`** so the health monitor workflow activates (scheduled + workflow_dispatch only fire from the default branch).
2. **WS 9 (tooltips)** — `load.tooltips.R` already loads `showPOSTooltip`, `showParcelsTooltip`, `selectParcelsTooltip`; quality of the markdown content in `inst/` is unknown — BC to review.
3. **WS 11 (BC-owned)** — deploy `mass_counties` and `mass_towns` to AcuGIS (primary GeoServer is back up; currently only on marsh01 fallback).
4. **Final QA + deploy** — BC to do a full end-to-end smoke test of the MA app, then deploy.

The plan + work log have the full detail.
