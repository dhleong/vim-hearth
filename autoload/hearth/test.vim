
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

    let ext = expand('%:e')
    if ext ==# 'cljc'
        " if there's a cljs namespace test file, run that; otherwise, fall
        " through below to try to run the right test
        let cljsPath = hearth#path#FileFromNs(ns, 'cljs')
        if !empty(cljsPath)
            call hearth#test#cljs#Run(cljsPath, ns)
            return
        endif
    endif

    if ext ==# 'cljs'
        let path = hearth#path#FileFromNs(ns, 'cljs')
        call hearth#test#cljs#Run(path, ns)
    else
        exe 'RunTests ' . ns
    endif
endfunc
