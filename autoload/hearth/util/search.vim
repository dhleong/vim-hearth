func! hearth#util#search#IsAcceptableNs(ns)
    " ignore re-frame-10x inlined deps
    return a:ns !~# 'inlined-deps'
endfunc
