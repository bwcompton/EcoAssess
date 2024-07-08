# ecoConnect.viewer.styles
# make GeoServer style files for stopgap ecoConnect viewer
# View palettes on https://r-charts.com/color-palettes/
# After running this, connect to the GeoServer via SFTP, and 
#    copy results to /appservers/apache-tomcat-8x/webapps/geoserver/data/workspaces/ecoConnect/styles/
# B. Compton, 3 Nov 2023
# 20 Nov 2023: change palette for floodplain forest
# 28 Jun 2024: add power-scaled palettes
# 1 Jul 2024: now creating .SLD files; new palettes that ramp down to white for ridgetops, wetlands,
#             and floodplain forests



source('make.style.R')


# normal single-scaled palettes
# make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests')
# make.style('ggthemes::Orange', name = 'ridgetops')
# make.style('ggthemes::Classic Blue', name = 'wetlands')
# make.style('ggthemes::Blue-Teal', name = 'floodplains')



# power-scaled palettes, for ecoConnect rescaling
powers <- seq(1, 3, 0.5)
for(i in powers) {
 #  make.style('grDevices::Greens 3', reverse = TRUE, power = i, white = TRUE, name = paste0('Forest_fowet', i))
 #  make.style('grDevices::Oranges', reverse = TRUE, power = i, white = TRUE, name = paste0('Ridgetop', i))
 #  make.style('grDevices::Oslo', power = i, white = TRUE, name = paste0('Nonfo_wet', i))
   make.style('grDevices::Teal', reverse = TRUE, power = i, white = TRUE, name = paste0('LR_floodplain_forest', i))
}

cat('.SLD files created. Now connect to the GeoServer via SFTP, and copy results to\n/appservers/apache-tomcat-8x/webapps/geoserver/data/workspaces/ecoConnect/styles/')


# test
# make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests1', power = 1)
# make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests2', power = 1.5)
# make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests3', power = 2)
# make.style('grDevices::Greens 3', reverse = TRUE, name = 'forests4', power = 2.5)

# IEI
make.style('grDevices::Greens 3', reverse = TRUE, name = 'iei_green100')
