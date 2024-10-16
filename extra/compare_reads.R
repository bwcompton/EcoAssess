# speed test for loading template vs shindex
# To use, run ecoConnect_tool.app, draw or upload poly, select Get report, and then interrupt and run this
# 15 Oct 2024


# shindex (32 bit)
g <- layers$server.names[l]; z <- rep(NA, 100); for(i in 1:100) {a <- Sys.time();x <- get.WCS.data(WCSserver, layers$workspaces[l], g, bbox);z[i]<-Sys.time() - a};summary(z)


# template (8 bit)
g <- 'template'; z <- rep(NA, 100); for(i in 1:100) {a <- Sys.time();x <- get.WCS.data(WCSserver, layers$workspaces[l], g, bbox);z[i]<-Sys.time() - a};summary(z)
