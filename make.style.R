'make.style' <- function(palette, count = 100, range = c(1, 100), reverse = FALSE, power = 1,
                         name = paste0(gsub('[: ]+', '_', palette), '_', count),
                         abstract = paste('GeoServer style from make.style for', name, 'using palette', palette), 
                         path = 'C:/Users/bcompton/Desktop/') {
   
   # Make an SLD 1.0 style file for raster legends on GeoServer
   # View palettes on https://r-charts.com/color-palettes/
   # Arguments:
   #   palette    argument to paletteer_c(), quoted package name and palette argument, 
   #              e.g., 'viridis::plasma'
   #   count      number of classes within range
   #   range      two element vector of range
   #   reverse    if TRUE, reverse order of colors
   #   power      Rescale colors by power, giving lighter colors at the low end for 
   #              powers > 1. Used for ecoConnect scaling in ecoConnect tool.
   #   name       name of style (result file will be name.txt)
   #   abstract   abstract line
   #   path       path to result file
   # Result:
   #   result file in SLD 1.0 format, ready to put up on GeoServer
   # Notes:       I'm using Viridis::plasma for IEIs. It's iei_viridisC100 on the GeoServer
   # B. Compton, 3 Nov 2023 (from make.viridis.style)
   # 28 Jun 2024: add power argument
   

   
   library(paletteer)
   
   
   v <- data.frame(cbind(seq(range[1], range[2], length.out = count), 
                         substr(paletteer_c(palette, count), 1, 7)))
   names(v) <- c('cutpoint', 'color')
   v$cutpoint <- as.numeric(v$cutpoint)
   if(reverse)
      v$color <- rev(v$color)
   
 #  v<<-v;power<<-power;return()
   
   if(power != 1) {                       # if using power rescaling, stretch palette
      x <- v$cutpoint ^ power
      y <- round(min(v$cutpoint) + ((x - min(x)) * (max(v$cutpoint) - min(v$cutpoint))) 
                 / (max(x) - min(x)))
      v$color <- v$color[y]
      abstract <- paste0(abstract, ', power rescaling = ', power)
   }
      
      
      
   
   z <- paste('              <ColorMapEntry color="', v$color, '" quantity="', 
              v$cutpoint, '"/>', sep = '')
   
   head <- c('<?xml version="1.0" encoding="windows-1252"?>',
             '<StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"',
             '  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
             '  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd">',
             '  <NamedLayer>',
             paste('    <Name>', name, '</Name>', sep = ''),
             '    <UserStyle>',
             paste('      <Name>', name, '</Name>', sep = ''),
             paste('      <Title>Style for ', name, '</Title>', sep = ''),
             paste('      <Abstract>', abstract, '</Abstract>', sep = ''),
             '      <FeatureTypeStyle>',
             '        <Rule>',
             '          <RasterSymbolizer>',
             '            <Opacity>1.0</Opacity>',
             '            <ColorMap>')   
   
   tail <- c('            </ColorMap>',
             '          </RasterSymbolizer>',
             '        </Rule>',
             '      </FeatureTypeStyle>',
             '    </UserStyle>',
             '  </NamedLayer>',
             '</StyledLayerDescriptor>')
   
   
   result <- paste(path, name, '.txt', sep = '')
   writeLines(c(head, z, tail), result)
   cat('Result written to ', result, '\n', sep = '')
}