
func! hearth#test#RunForBuffer()
    " Run the appropriate tests for the current buffer. If this is not
    " a test ns, we will run the associated -test ns
    " This will automatically write the file if it's not saved

    if &modified
        w
        redraw!
    endif

    let ns = fireplace#ns()
    if ns !~# '-test$'
        let ns = ns . '-test'
    endif

    silent :Require
    if expand('%:e') ==# 'cljs'
        call hearth#test#cljs#Run(ns)
    else
        exe 'RunTests ' . ns
    endif
endfunc
