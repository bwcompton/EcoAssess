shinyjs.fullscreen_on = function(par) {
                  var def_par = {seq: 'test message'};
                  par = shinyjs.getParams(par, def_par);
                  alert(par.seq);
}