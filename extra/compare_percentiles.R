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



x <- readRDS('x:/LCC/GIS/Final/ecoRefugia/ecoConnect_final/ecoConnect_quantiles.RDS')

path <- 'x:/LCC/GIS/Final/ecoRefugia/ecoConnect_final/'

x <- data.frame(xx = x[,1])
x$single <- readRDS(paste0(path, 'ecoConnect_quantiles.RDS'))$Forest_fowet
x$a1 <- readRDS(paste0(path, 'ecoConnect_quantiles_1.RDS'))$Forest_fowet
x$a10 <- readRDS(paste0(path, 'ecoConnect_quantiles_10.RDS'))$Forest_fowet
x$a50 <- readRDS(paste0(path, 'ecoConnect_quantiles_50.RDS'))$Forest_fowet

x$a100 <- readRDS(paste0(path, 'ecoConnect_quantiles_100.RDS'))$Forest_fowet


lines(x$single, col = 'black')
plot(1:100, x$a1, ty = 'l', col = 'red')
#lines(x$a1b, col = 'green')
lines(x$a10, col = 'blue')
lines(x$a50, col = 'orange')
lines(x$a100, col = 'purple')


x$new <- readRDS(paste0(path, 'ecoConnect_quantiles.RDS'))$Forest_fowet
lines(x$new, col = 'cyan')
