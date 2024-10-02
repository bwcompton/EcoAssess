# Compare percentiles for ecoConnect across various block sizes
# Read new-style percentile files (as of September 2024) and plot curves by acres
# 20 Sep 2024 (rewrite of July 3 version)



postfix = 'new1e5'
if(postfix != '')
   postfix <- paste0('_', postfix)


colors <- c('red', 'orange', 'green', 'blue', 'purple', 'black', 'gray')
acres <- format(10^(0:6), big.mark = ',', scientific = FALSE)


x <- readRDS(paste0('x:/LCC/GIS/Final/ecoRefugia/ecoConnect_final/ecoConnect_quantiles', postfix, '.RDS'))
x <- x$full[1, , , , ]         # size, system, all vs best, percentile
x <- x[, 1, 1, ]                         # size, percentile

plot(x[1, ], 1:100, col = colors[1], ty = 'l', lwd = 2, xlim = c(0, 100), xlab = 'Mean ecoConnect for block', ylab = 'Percentile',
     main = 'Percentiles for ecoConnect')
for(i in 2:dim(x)[1])
   lines(x[i, ], 1:100, col = colors[i], ty = 'l', lwd = 2)

legend(75, 25, acres[1:dim(x)[1]], col = colors[1:dim(x)[1]], lwd = 2, title = 'Acres in block', bty = 'n')
