# check.quantile.scale
# Are percentiles linear or logarithmic?
# Strategy: interpolate between say area = 10 and area = 1000, and compare with actual values for area = 100
# They're clearly linear
# B. Compton, 2 Oct 2024



x <- t(quantiles$full[1, , 'forests', 'all', ])
colnames(x) <- gsub(' ', '', format(as.numeric(colnames(x))))
# areas <- c('10', '100', '1000')
areas <- c('100', '1000', '10000')
# areas <- c('1000', '10000', '100000')

scale <- c(0.5, 0.5); plot(x[, areas[2]], x[, areas[1]] * scale[1] + x[, areas[3]] * scale[2], xlim = c(0, 100), ylim = c(0, 100), 
                           main = 'linear'); abline(0, 1)
scale <- c(0.1, 0.9); plot(x[, areas[2]], x[, areas[1]] * scale[1] + x[, areas[3]] * scale[2], xlim = c(0, 100), ylim = c(0, 100),
                           main = 'logarithmic'); abline(0, 1)



