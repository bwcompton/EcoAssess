# Updating the bundled Matomo tracker in EcoAssess

EcoAssess serves the Matomo tracker script as a first-party file (`www/matomo-tracker.js`)
to avoid browser tracking-protection blocks. After upgrading Matomo, refresh this file so
the app stays in sync with the server.

## Steps

1. On the server (or from any machine that can reach it), download the updated tracker:

   ```bash
   curl -o matomo-tracker.js https://marsh01.ecs.umass.edu/matomo/matomo.js
   ```

2. Copy `matomo-tracker.js` into `EcoAssess/www/` (replacing the old file).

3. Commit and redeploy the app.

## Notes

- `www/matomo.js` (the local init script) does **not** need to change — it already points
  to `matomo-tracker.js` rather than fetching from the server.
- The data endpoint (`matomo.php` on marsh01) is unchanged; only the tracker script is
  bundled locally.
- If you ever move Matomo to a different server, update the `u=` URL in `www/matomo.js`
  as well.
