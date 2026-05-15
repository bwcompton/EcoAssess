# Read MassGIS parcel data as an sf object
# Proof of concept for MA EcoAssess project
# This is displaying for all of Warwick; MassMapper doesn't turn on parcels until 2 zoom levels closer
# B. Compton, 16 Oct 2025
# 12 May 2026: MassGIS changed the URL on 2 Apr 2026



library(leaflet)
library(sf)
library(arcgislayers)



wick <- st_read('C:/GIS/GIS/Warwick/warwick.shp')           # read Warwick boundaries to get bounding box
bbox <- st_bbox(wick)


a <- Sys.time()

url <- 'https://services1.arcgis.com/hGdibHYSPO59RG1h/arcgis/rest/services/Massachusetts_Property_Tax_Parcels/FeatureServer/0'             # Parcels - new REST URL, as of 2 Apr 2026
field <- 'OWNER1'

# url <- 'https://arcgisserver.digital.mass.gov/arcgisserver/rest/services/AGOL/openspace/FeatureServer/0'         # Protected open space
# field <- 'LEV_PROT'



layer <- arc_open(url)
poly <- arc_select(layer, fields = field, filter_geom = st_as_sfc(bbox))
poly2 <- st_transform(poly, crs = 4326)

leaflet(data = poly2) |>
   addTiles() |>
   addPolygons(data = poly2)

message('Time taken: ', Sys.time() - a, ' sec')
