'geoserver.probe' <- function(url, seconds = 8) {

   # geoserver.probe
   # Ping a GeoServer and report whether it answered, logging the reason when
   # it didn't. The silent version of this threw the reason away, which made
   # the 10 Sep 2026 failover test undiagnosable from the console.
   # Arguments:
   #     url         base GeoServer URL (geoserver$primary or geoserver$fallback)
   #     seconds     give up on a dead or hung host after this long
   # Result:
   #     TRUE if the server returned HTTP 200, else FALSE
   # B. Compton, 10 Sep 2026



   r <- tryCatch(GET(url, timeout(seconds)), error = function(e) e)      # explicit timeout: libcurl's default is 300 s

   if(inherits(r, 'error')) {                                           # unreachable: refused, DNS, TLS, or timed out
      message('GeoServer probe ', url, ' FAILED: ', conditionMessage(r))
      return(FALSE)
   }

   if(status_code(r) != 200) {                                          # answered, but not with the GeoServer home page
      message('GeoServer probe ', url, ' FAILED: HTTP ', status_code(r))
      return(FALSE)
   }

   message('GeoServer probe ', url, ' OK')
   TRUE
}
