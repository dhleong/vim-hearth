func! hearth#util#SessionExists()
    " Check if there's an existing session for the current file/ns

    try
        call fireplace#client()
        return 1
    catch /Fireplace:.*REPL/
        return 0
    endtry
endfunc

