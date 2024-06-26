// Set entire browser window to fullscreen or normal screen
// Argument:
//      full        true for fullscreen, or false to exit fullscreen
// B. Compton, 26 Jun 2024 (source: https://developer.mozilla.org/en-US/docs/Web/API/Document/exitFullscreen)



shinyjs.fullscreen = function toggleFullscreen(full) {
  let elem = document.body;

  if (full == 'true') {
    elem.requestFullscreen();
  } else {
    document.exitFullscreen();
  }
}
