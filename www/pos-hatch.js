// pos-hatch.js - SVG hatch fill for POS polygons (Massachusetts mode).
// Called via session$sendCustomMessage('applyPosHatch', list()) from pos.server.R
// the first time POS polygons are added. Sets up a MutationObserver on the
// pos-pane so every path added thereafter (new viewport fetches, zoom-gating
// show/hide cycles) is hatched immediately rather than via a one-shot timeout.

Shiny.addCustomMessageHandler('applyPosHatch', function(message) {
   var mapEl = document.getElementById('map');
   if (!mapEl) return;
   var widget = HTMLWidgets.getInstance(mapEl);
   if (!widget) return;
   var pane = widget.getMap().getPanes()['pos-pane'];
   if (!pane) return;

   function ensureDefs() {
      var svg = pane.querySelector('svg');
      if (!svg || svg.querySelector('#posHatch')) return;
      var ns   = 'http://www.w3.org/2000/svg';
      var defs = document.createElementNS(ns, 'defs');
      defs.innerHTML =
         '<pattern id="posHatch" patternUnits="userSpaceOnUse" width="40" height="40">' +
            '<line x1="0" y1="40" x2="40" y2="0" stroke="#00DD00" stroke-width="0.7"/>' +
         '</pattern>';
      svg.insertBefore(defs, svg.firstChild);
   }

   function hatchPath(path) {
      ensureDefs();
      path.style.fill        = 'url(#posHatch)';
      path.style.fillOpacity = '1';
   }

   // Hatch all paths already in the pane.
   ensureDefs();
   pane.querySelectorAll('path').forEach(hatchPath);

   // Watch for every future path addition (viewport fetches, zoom-gate cycles).
   if (!pane._posHatchObserver) {
      pane._posHatchObserver = new MutationObserver(function(mutations) {
         mutations.forEach(function(m) {
            m.addedNodes.forEach(function(node) {
               if (node.nodeName === 'path') {
                  hatchPath(node);
               } else if (node.querySelectorAll) {
                  node.querySelectorAll('path').forEach(hatchPath);
               }
            });
         });
      });
      pane._posHatchObserver.observe(pane, { childList: true, subtree: true });
   }
});
