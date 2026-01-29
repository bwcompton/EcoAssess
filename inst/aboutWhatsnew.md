**Version 1.1.0 (January 29, 2026)**

- We finally have our own GeoServer up and running. This version falls back to a second GeoServer
  if the first one is down, so this app is now far more reliable.

**Version 1.0.2 (January 9, 2025)**

- Respond more robustly to a crashed GeoServer.

**Version 1.0.1 (November 21, 2024)**

- Added a 300 ms delay to tooltips so they don't pop up so eagerly

**Version 1.0.0 (November 12, 2024)**

- Version rollover for public release. No additional changes---beta is performing well so far.

**Beta version 0.3.0 (November 8, 2024)**

##### New features
- Zipped shapefiles may now be uploaded as an alternative to component files
- Added an additional basemap layer, Open Street Map. It's got a lot of detail.
- Added two new basemap overlays,
   + State and county boundaries
   + User basemap. You can now upload a shapefile as an additional basemap overlay. This allows
uploading open space or parcels in the vicinity of project areas. These files can't be huge, but
open space for a county or parcels for a town generally work fine. Open space for an entire state 
is definitely too much.

##### Report changes
- ecoConnect percentiles are now reported relative to the entire region, the state, and the HUC 8 watershed
- Percentiles for ecoConnect are now based on sampling of random squares of varying sizes (1, 10, ... 1,000,000 
acres) across the region, and reported percentiles are interpolated from the two nearest sizes. This removes 
the confounding effect of project area size.
- "All" and "best" are now in a field called "focus," and best for IEI is now based on the top 50% of cells
while best for ecoConnect is for the top 25%
- Changed the layout of the table, rearranged sections of the report, and improved descriptions
- Included state name and HUC 8 watershed id in report
- Added a footnote for project areas that cross state or watershed boundaries
- Added scalebars to maps in report


##### Other changes
- The full screen toggle has been moved to the bottom of the right panel, to make more space
on small screens for layers
- "ecoConnect scaling" is now called "ecoConnect display"
- ecoConnect display and Layer opacity are now disabled when corresponding layers aren't selected
- Tooltips and "About this site" have been updated for clarity and to describe new features
- Added version number and "What's new" 
- The project name (if supplied) is now used as the report filename, after scrubbing illegal characters
- The app has been renamed to "EcoAssess"
- We've added a new 
<a href="https://umassdsl.org/index-of-ecological-integrity/" target="_blank" rel="noopener 
noreferrer">IEI home page</a>
to the DSL website

##### Bug fixes and robustness
- Polygon clipping failure gave incorrect scores; fixed
- Crashed when project area was too small; introduced minimum of 1 acre
- Some project area polygons were distorted; fixed
- Polygon with crossing lines caused a crash; fixed
- Now catches errors caused by project area outside of Northeast, or in the ocean or estuarine rivers


**Beta version 0.2.0 (July 17, 2024)**

- Initial public beta release
