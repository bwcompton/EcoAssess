# ecoConnect.viewer.styles
# make GeoServer style files for stopgap ecoConnect viewer
# View palettes on https://r-charts.com/color-palettes/
# B. Compton, 3 Nov 2023
# 20 Nov 2023: change palette for floodplain forest
# 28 Jun 2024: add power-scaled palettes




source('g:/R/ecoConnect.viewer/make.style.R')


# normal single-scaled palettes
# make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests')
# make.style('ggthemes::Orange', name = 'ridgetops')
# make.style('ggthemes::Classic Blue', name = 'wetlands')
# make.style('ggthemes::Blue-Teal', name = 'floodplains')



# power-scaled palettes, for ecoConnect rescaling
for(i in 1:3) {
   pow <- i
     # pow <- i / 2 + 0.5              # powers are 1, 1.5, 2, 2.5
   make.style('grDevices::Greens 3', reverse = TRUE, power = pow, name = paste0('forests', i))
   make.style('ggthemes::Orange', power = pow, name = paste0( 'ridgetops', i))
   make.style('ggthemes::Classic Blue', power = pow, name = paste0('wetlands', i))
   make.style('ggthemes::Blue-Teal', power = pow, name = paste0('floodplains', i))
}



# test
make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests1', power = 1)
make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests2', power = 1.5)
make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests3', power = 2)
make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests4', power = 2.5)
