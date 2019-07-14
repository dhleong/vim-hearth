
func! s:RunCljsTests(ns)
    let ns = a:ns
    let testExpr = "(cljs.test/run-tests '" . ns . ')'
    let expr = '(symbol'
            \. '  (with-out-str '
            \. "    (cljs.core/require '" . ns . ' :reload)'
            \.      testExpr . '))'
    let result = fireplace#eval(expr)

    if stridx(result, 'FAIL') == -1 && stridx(result, 'ERROR') == -1
        echo testExpr
    else
        " TODO can we put this into the qflist?
        echo result
    endif
endfunc

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
        call s:RunCljsTests(ns)
    else
        exe 'RunTests ' . ns
    endif
endfunc
