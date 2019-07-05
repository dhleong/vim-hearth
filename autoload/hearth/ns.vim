func! hearth#ns#TryRequire()
    " :Require the current ns, but only if there's an active session

    if !hearth#util#SessionExists()
        return
    endif

    try
        silent :Require
    catch /Fireplace:.*REPL/
        redraw! | echohl Error | echo 'No REPL found' | echohl None
    catch /nREPL/
        redraw! | echohl Error | echo 'No REPL found' | echohl None
    endtry
endfunc
