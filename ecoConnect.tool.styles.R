# ecoConnect.viewer.styles
# make GeoServer style files for stopgap ecoConnect viewer
# View palettes on https://r-charts.com/color-palettes/
# B. Compton, 3 Nov 2023
# 20 Nov 2023: change palette for floodplain forest



source('g:/R/ecoConnect.viewer/make.style.R')


make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests')
make.style('ggthemes::Orange', name = 'ridgetops')
make.style('ggthemes::Classic Blue', name = 'wetlands')
make.style('ggthemes::Blue-Teal', name = 'floodplains')
