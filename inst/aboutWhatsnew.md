**Beta version 0.2.0 (July 30, 2024)**

##### New features
- Zipped shapefiles may now be uploaded
- An additional basemap layer, Open Street Map. It's got a lot of detail.
- Two new basemap overlays,
   + State and county boundaries
   + User basemap. You can now upload a shapefile as an additional basemap overlay. This allows
uploading open space or parcels for the vicinity of project areas. These files can't be huge, but
open space for a county or parcels for a town generally work fine. Open space for an entire state 
is definitely too much. (We tried adding PAD-US as an open space layer, but the way that USGS 
chose to serve these data makes the app horribly sluggish, so we added user basemaps instead).

##### Report changes
- 

##### Other changes
- The full screen toggle has been moved to the bottom of the right panel, to make more space
on small screens for layers
- "ecoConnect scaling" is now called "ecoConnect display."
- ecoConnect display and Layer opacity are now disabled when corresponding layers aren't selected
- Tooltips and About this site have been updated for clarity and to describe new features
- The version number and "What's new" have been added. We'll drop these for the final rollout, but
wanted to keep Beta users updated about what's changed