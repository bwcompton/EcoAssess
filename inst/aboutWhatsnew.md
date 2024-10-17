**Beta version 0.2.0 (October 16, 2024)**

##### New features
- Zipped shapefiles may now be uploaded
- An additional basemap layer, Open Street Map. It's got a lot of detail.
- Two new basemap overlays,
   + State and county boundaries
   + User basemap. You can now upload a shapefile as an additional basemap overlay. This allows
uploading open space or parcels for the vicinity of project areas. These files can't be huge, but
open space for a county or parcels for a town generally work fine. Open space for an entire state 
is definitely too much. (We tried adding PAD-US as an open space layer, but the way that USGS 
chose to serve these data made the app horribly sluggish, so we added user basemaps instead).

##### Report changes
- ecoConnect percentiles are now reported relative to the entire region, the state, and the HUC 8 watershed
- Percentiles for ecoConnect are now based on sampling of random squares of varying sizes (1, 10, ... 1,000,000 
acres) across the region, and reported percentiles are interpolated from the two nearest sizes. This removes 
the confounding effect of project area size.
- Change the layout of the table, rearrange sections of the report, and improve descriptions
- Include state name and HUC 8 watershed id in report
- Added scalebars to maps in report

##### Other changes
- The full screen toggle has been moved to the bottom of the right panel, to make more space
on small screens for layers
- "ecoConnect scaling" is now called "ecoConnect display."
- ecoConnect display and Layer opacity are now disabled when corresponding layers aren't selected
- Tooltips and About this site have been updated for clarity and to describe new features
- The version number and "What's new" have been added. We'll drop these for the final rollout, but
wanted to keep Beta users updated about what's changed
- The project name (if supplied) is now used as the report filename, after scrubbing illegal characters.

##### Bug fixes
- Polygon clipping failure gave incorrect scores
- Crashed when project area was too small; introduced minimum of 1 acre
- Some project area polygons were distorted; fixed
- Prevent error from project area polygon with crossing lines
- Now catches errors caused by project area outside of Northeast, or in the ocean or estuarine rivers