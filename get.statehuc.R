'get.statehuc' <- function(shindex, states, hucs) {
   
   # Get primary and secondary state and HUC for project area
   # Arguments:
   #     shindex        state and huc index (sshhh), raster, clipped to user poly, subtidal masked out
   #     states, hucs   state and huc directories, from RDS
   # Results (4 element list)
   #     state          state number
   #     huc            huc number
   #     state.text     name of primary and potentially secondary states (formatted text)
   #     huc.text       ID of primary and potentially secondary HUCs (formatted text)
   # B. Compton, 30 Sep 2024
   
   
   
   x <- as.vector(shindex)
   state <- floor(x / 1000)
   huc <- x - state * 1000
   
   s <- as.numeric(names(sort(table(state), decreasing = TRUE)))
   h <- as.numeric(names(sort(table(huc), decreasing = TRUE)))
   z <- list(state = s[1], huc = h[1])
   
   z$state.text <- switch(min(length(s), 3),                                # Pretty formatted list of states (3 is the most possible in the NER, but we'll play it safe)
                          states$state[s[1]],
                          paste(states$state[s[1:2]], collapse = ' and '),
                          paste(paste(states$state[s[-length(s)]], collapse = ', '), states$state[s[length(s)]], sep = ', and '))
   
   z$huc.text <- paste0('HUC 8 watershed', (ifelse(length(h) > 1, 's ', ' ')), 
                        switch(min(length(h), 3),                                  # Pretty formatted list of hucs
                               sprintf('%08d', hucs$HUC8_code[h[1]]),
                               paste(sprintf('%08d', hucs$HUC8_code[h[1:2]]), collapse = ' and '),
                               paste(paste(hucs$HUC8_code[h[-length(h)]], collapse = ', '), sprintf('%08d', hucs$HUC8_code[h[length(h)]]), sep = ', and ')))
   z$footnote.text <- ifelse((length(s) > 1) | (length(h) > 1),
                             '^[For project areas that cross state or watershed boundaries, percentiles are based on the site\'s majority state or watershed, listed first.]',
                             '')
   z
}