'modalHelp' <- function(text, title, size = 'm') {

   # Show a modal window within an observe in Shiny
   # Arguments:
   #     text     text to display, usually from includeMarkdown()
   #     title    title of help window
   #     window   size, one of s, m, l, xl. Default is 'm'
   # B. Compton, 21 Jul 2023



   showModal(modalDialog(
      text, title = title, easyClose = TRUE, fade = TRUE, footer = modalButton('OK'), size = size)
   )
}
