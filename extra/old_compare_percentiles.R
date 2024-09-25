# Compare percentiles for ecoConnect across various sample area, in acres
# the first plot, in red, is my original sample of single cells. Notably, I was excluding zeros 
# in this version, which I thought made sense at the time. It makes less sense when sampling areas,
# so I switched to excluding zeros and nodata. The differences from 1 cell to 100 acres are 
# nicely systematic. I changed ecoconnect.quantiles to include the entire landscape (from mask).
# Both versions should do the same thing now. It looks like they do.
# 
# Source code: X:/LCC/Code/ecoRefugia/ecoconnect.big.quantiles.R and ecoconnect.quantiles.R
# 
# 3 Jul 2024
# axis transposed, 20 Sep 2024


cat('************ OLD VERSION ***************\n')


x <- readRDS('x:/LCC/GIS/Final/ecoRefugia/zzold_ecoConnect_final/ecoConnect_quantiles.RDS')

path <- 'x:/LCC/GIS/Final/ecoRefugia/zzold_ecoConnect_final/'

x <- data.frame(xx = x[,1])
x$single <- readRDS(paste0(path, 'ecoConnect_quantiles.RDS'))$Forest_fowet
x$a1 <- readRDS(paste0(path, 'ecoConnect_quantiles_1.RDS'))$Forest_fowet
x$a10 <- readRDS(paste0(path, 'ecoConnect_quantiles_10.RDS'))$Forest_fowet
x$a50 <- readRDS(paste0(path, 'ecoConnect_quantiles_50.RDS'))$Forest_fowet

x$a100 <- readRDS(paste0(path, 'ecoConnect_quantiles_100_1e5.RDS'))$Forest_fowet


plot(x$single, 1:100, col = 'black', ty = 'l', lwd = 2)
#plot(x$a1, 1:100, ty = 'l', col = 'red', lwd = 2)
#lines(x$a1b, 1:100, col = 'green', lwd = 2)
lines(x$a10, 1:100, col = 'blue', lwd = 2)
lines(x$a50, 1:100, col = 'orange', lwd = 2)
lines(x$a100, 1:100, col = 'purple', lwd = 5)   # we use this


# x$new <- readRDS(paste0(path, 'ecoConnect_quantiles.RDS'))$Forest_fowet
# lines(x$new, 1:100, col = 'cyan', lwd = 2)
