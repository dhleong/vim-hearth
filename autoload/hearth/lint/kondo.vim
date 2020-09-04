func! s:expand(lint)
    " try default stuff first:
    call hearth#lint#errors#Expand(a:lint)
    if hearth#lint#errors#Exists(a:lint)
        return 1
    endif

    " kondo-specific errors:

    let match = matchlist(a:lint.text, 'Unresolved namespace \([^ ,.]*\)')
    if !empty(match)
        let ns = match[1]
        let a:lint.end_col = a:lint.col + len(ns)
        call hearth#lint#errors#Pack(a:lint, 'ns', ns)
        return 1
    endif

    let match = matchlist(a:lint.text, 'unresolved symbol \([^ ,.]*\)$')
    if !empty(match)
        let symbol = match[1]
        if a:lint.col > 1
            let a:lint.end_col = a:lint.col + len(symbol)
        endif
        call hearth#lint#errors#Pack(a:lint, 'symbol', symbol)
        return 1
    endif

    let match = matchlist(a:lint.text, 'namespace \([^ ]*\) is required but never used$')
    if !empty(match)
        let ns = match[1]
        if a:lint.col > 1
            let a:lint.end_col = a:lint.col + len(ns)
        endif
        call hearth#lint#errors#Pack(a:lint, 'unused-ns', ns)
        return 1
    endif
endfunc

func! hearth#lint#kondo#Extract(list)
    let lints = a:list
    if !len(lints)
        return []
    endif

    let result = []
    for lint in lints
        if s:expand(lint)
            let result = add(result, lint)
        endif
    endfor

    return result
endfunc
