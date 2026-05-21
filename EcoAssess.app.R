# EcoAssess.app.R - ecoConnect and IEI viewing and reporting tool
# Before initial deployment on shinyapps.io, need to restart R and:
#    library(remotes); install_github('https://github.com/elipousson/sfext.git'); install_github('bwcompton/leaflet.lagniappe')
# YOu'll need to get a Stadia Maps API  key from https://client.stadiamaps.com and save it in www/stadia_api.txt. Make sure
# to .gitignore this file!

# B. Compton



library(shiny)
library(bslib)
library(bsicons)
library(shinyjs)
library(shinybusy)
library(shinyWidgets)
library(htmltools)
library(markdown)
library(leaflet)
library(leaflet.extras)
library(leaflet.lagniappe)
library(terra)
library(sf)
library(future)
library(promises)
library(ggmap)
library(ggplot2)
library(ggspatial)            # We're using Ethan's new annotation-scale.R. Delete local version when PR https://github.com/paleolimbot/ggspatial/pull/129 is accepted & rolled out
### library(geosphere)        # don't want to attch this, as it masks `span`, but sure need to install it!
library(httr)                 # for pinging GeoServer
###library(leaflet.esri)      # test, for PAD-US. It sucks


plan('multisession')


# All app data, tooltips, helpers, and the make.ui / make.server entry points
# are auto-loaded from R/ at app start (Shiny >= 1.5). The cfg list resolved
# from the URL query string (?regional=true|false) drives the regional vs.
# Massachusetts mode -- see R/resolve.cfg.R, R/make.ui.R, R/make.server.R.


ui     <- function(request) make.ui(resolve.cfg(request$QUERY_STRING))
server <- make.server

shinyApp(ui, server)
