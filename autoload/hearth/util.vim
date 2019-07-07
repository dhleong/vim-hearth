func! hearth#util#SessionExists()
    " Check if there's an existing session for the current file/ns

    try
        call fireplace#client()
        return 1
    catch /Fireplace:.*REPL/
        return 0
    endtry
endfunc

func! hearth#util#Stringify(string)
    return '"' . escape(a:string, '"\') . '"'
endfunc

func! hearth#util#Symbolify(symbol)
    if a:symbol =~# '^[[:alnum:]?*!+/=<>.:-]\+$'
        return "'" . a:symbol
    else
        return '(symbol ' . hearth#util#Stringify(a:symbol) . ')'
    endif
endfunc
