# zoomtest - messing around with picking the proper map scales and zoom levels
# I've saved various example polys of different sizes, shapes, and settings
# The regression to get the zoom from the map size is below
# B. Compton, 17-18 Jun 2024



# saveRDS(october, 'c:/temp/october.RDS')
# saveRDS(compton, 'c:/temp/compton.RDS')
# saveRDS(aica, 'c:/temp/aica.RDS')
# saveRDS(burrage, 'c:/temp/burrage.RDS')
# saveRDS(xxpoly, 'c:/temp/catamount.RDS')
# saveRDS(xxpoly, 'c:/temp/teca.RDS')
# saveRDS(xxpoly, 'c:/temp/ctriv.RDS')

left <- 1.5
right <- 5

poly <- readRDS('c:/temp/october.RDS')
plot(make.report.maps(poly, left, 1000))  # size = 19570
plot(make.report.maps(poly, right, 6000))  # size = 78281

poly <- readRDS('c:/temp/compton.RDS')
plot(make.report.maps(poly, left, 1000))  # size = 1000
plot(make.report.maps(poly, right, minsize = 6000))   # size = 24000

poly <- readRDS('c:/temp/aica.RDS')
plot(make.report.maps(poly, left, 1000))  # size = 2071
plot(make.report.maps(poly, right, minsize = 6000))  # size = 24000

poly <- readRDS('c:/temp/burrage.RDS')
plot(make.report.maps(poly, left, 1000))  # size = 5415 (ugly)
plot(make.report.maps(poly, right, minsize = 6000))   # size = 24000

poly <- readRDS('c:/temp/catamount.RDS')
plot(make.report.maps(poly, left, 1000))  # size = 3656 (ugly)
plot(make.report.maps(poly, right, minsize = 6000))   # size = 24000

poly <- readRDS('c:/temp/teca.RDS')
plot(make.report.maps(poly, left, 1000))  # size = 1332
plot(make.report.maps(poly, right, minsize = 6000))   # size = 24000

poly <- readRDS('c:/temp/ctriv.RDS')
plot(make.report.maps(poly, left, 1000))  # size = 12498 (ugly)
plot(make.report.maps(poly, right, minsize = 6000))   # size = 49992


# universal. Set poly first
plot(make.report.maps(poly, left, 15))
plot(make.report.maps(poly, 10, 13))


# New plan: add minsize to max statement
# print out final size
# use final size and the zoom I like in a regression to get slope and intercept for size -> zoom


# use a regression to get zoom from size based on zooms I picked by eye
x <- read.csv('C:/Work/R/ecoConnect.tool/extra/size_zoom.csv')

# linear. r^2 = 0.7
fit <- lm(zoom ~ size, x)
summary(fit)
plot(zoom ~ size, x)
abline(fit)

# add squared term. R^2 = 0.875. Will need to use size <- pmin(size, 60000) so we don't curve back up for huge sizes
fit <- lm(zoom ~ poly(size, 2, raw = TRUE), x)
x$size <- pmin(x$size, 60000)
summary(fit)
plot(zoom ~ size, x)
curve(predict(fit, newdata = data.frame(size = x)), add = TRUE)
