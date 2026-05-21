'tipped' <- function(text, tooltip, delay = 300)                                            # display text with a tooltip
   span(text, tooltip(bs_icon('info-circle'), tooltip, options = list(delay = delay)))
