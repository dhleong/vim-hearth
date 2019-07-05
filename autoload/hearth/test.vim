
func! s:RunCljsTests(ns)
    let ns = a:ns
    let testExpr = "(cljs.test/run-tests '" . ns . ')'
    let expr = '(do ' .
                \ "(cljs.core/require '" . ns . ' :reload)' .
                \ testExpr . ')'
    let resp = fireplace#client().eval(
        \ expr,
        \ {'ns': ns},
        \ )

    if has_key(resp, 'out')
        if stridx(resp.out, 'FAIL') == -1 && stridx(resp.out, 'ERROR') == -1
            " TODO can we put this into the qflist?
            echo testExpr
        else
            echo resp.out
        endif
        return
    endif

    " something terrible happened;
    " upgrading cider/piggieback fixed this for me
    echo 'Error: No `out` response'
    echo resp
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
