'switch.url' <- function(cfg, carry = list()) {

   # switch.url
   # Build the relative URL the in-app switch link navigates to. Flips the
   # `regional` flag and appends whatever session state make.server hands over
   # in `carry` (display layer, basemap, opacity, map view, ... -- decision 7),
   # so the other version comes up in the same state. With an empty `carry`,
   # the other version opens fresh at its own home.
   #
   # Arguments:
   #     cfg     current session's cfg list (from resolve.cfg)
   #     carry   named list of state to carry across; entries that are NULL or
   #             not length-1 are dropped. resolve.cfg parses these back out.
   # Result:
   #     a relative URL (a query string) to navigate to
   # B. Compton, 20-22 May 2026


   flag  <- if(cfg$regional) 'regional=false' else 'regional=true'
   carry <- carry[lengths(carry) == 1L]                 # drop NULL / empty entries
   if(!length(carry))
      return(paste0('?', flag))

   vals <- vapply(carry, function(v) utils::URLencode(as.character(v), reserved = TRUE), '')
   paste0('?', flag, '&', paste0(names(carry), '=', vals, collapse = '&'))
}
