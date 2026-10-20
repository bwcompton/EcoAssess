var _paq = window._paq = window._paq || [];/* tracker methods like "setCustomDimension" should be called before "trackPageView" */
    _paq.push(['trackPageView']);
    _paq.push(['enableLinkTracking']);
    (function() {
        var u="//marsh01.ecs.umass.edu/matomo/";
        // accurately measure the time spent in the visit
        _paq.push(['setTrackerUrl', u+'matomo.php']);
        _paq.push(['setSiteId', '10']);
        var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
        g.async=true; g.src='matomo-tracker.js'; s.parentNode.insertBefore(g,s);
    })();
