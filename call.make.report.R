'call.make.report' <- function(layer.data, resultfile, layers, poly, poly.proj, proj.name, proj.info, quick, params, session) {
   
   # call.make.report
   # cover function to call make.report in the future
   # Simply passes through all arguments for make.report, with the addion of session to support toast
   # B. Compton, 25 Jun 2024
   
   
   
   making.report <- showNotification('Generating report...', duration = NULL, closeButton = FALSE, session = session)
   
  # cat('In call.make.report...\n')
   report.promise <- future_promise({
      cat('*** PID ', Sys.getpid(), ' is writing the report in the future...\n', sep = '')
      make.report(layer.data, resultfile, layers, poly, poly.proj, proj.name, proj.info)      # write the report in the future
   }, seed = TRUE)                                           
   
   then(report.promise, onFulfilled = function(x) {
  #    cat('\n*** report.promise has been fulfilled!\n')
      removeNotification(making.report, session = session)
   })
}