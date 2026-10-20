'error.message' <- function(error) {
   
   # display an error message
   # Argument:
   #     error       Error name, part of an RMarkdown filename inst/error____.md
   # B. Compton, 4 Oct 2024

   
   
   showModal(modalDialog(
      title = 'Error', 
      includeMarkdown(paste0('inst/error', error, '.md')),
      footer = modalButton('OK'),
      easyClose = TRUE
   ))
}