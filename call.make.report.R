'call.make.report' <- function(layer.data, resultfile, layers, poly, poly.proj, proj.name, proj.info, quick, params, session) {
   
   # call.make.report
   # cover function to call make.report in the future
   # Simply passes through all arguments for make.report, with the addion of session to support toast
   # Source data:
   #     inst/ecoConnect_quantiles.RDS    percentiles of each ecoConnect layer, from ecoconnect.quantiles.R. Set GLOBALLY to share with 
   #                                      other Shiny sessions. Note we have to do this before we go into the future.
   # B. Compton, 25 Jun 2024
   
   
   
   cat('In call.make.report...\n')

   
   making.report <- showNotification('Generating report...', duration = NULL, closeButton = FALSE, session = session)
   
   
   if(!exists('quantiles'))
      quantiles <<- readRDS('inst/ecoConnect_quantiles.RDS')      # region-wide percentiles, from ecoConnect.quantiles. Set GLOBALLY because it's nice to share.
   
   
   report.promise <- future_promise({
      cat('*** PID ', Sys.getpid(), ' is writing the report in the future...\n', sep = '')
      make.report(layer.data, resultfile, layers, poly, poly.proj, proj.name, proj.info, quantiles)      # write the report in the future
   }, seed = TRUE)                                           
   
   then(report.promise, onFulfilled = function(x) {
  #    cat('\n*** report.promise has been fulfilled!\n')
      removeNotification(making.report, session = session)
   })
}