func! s:onFileLoaded(bufnr, resp) abort
    " if we have mantel, kick off a highlight proc after the
    " file has been loaded
    if bufnr('%') != a:bufnr
        " in a different buffer; don't bother
        return
    endif

    try
        call mantel#Highlight()
    catch /E117/
        " not installed; ignore
    endtry
endfunc

func! hearth#ns#TryRequire()
    " :Require the current ns, but only if there's an active session

    if !hearth#util#SessionExists()
        return
    endif

    try
        if expand('%:e') ==# 'cljs' && fireplace#op_available('load-file')
            call fireplace#message({
                \ 'op': 'load-file',
                \ 'file-path': expand('%:p'),
                \ }, function('s:onFileLoaded', [bufnr('%')]))
        else
            silent :Require
        endif
    catch /Fireplace:.*REPL/
        redraw! | echohl Error | echo 'No REPL found' | echohl None
    catch /nREPL/
        redraw! | echohl Error | echo 'No REPL found' | echohl None
    endtry
endfunc
