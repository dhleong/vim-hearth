func! hearth#lint#errors#Pack(lint, type, info)
    " Attach an error 'type' and 'info' (both strings) to the
    " given lint dictionary
    let a:lint.nr = a:type . ':' . a:info
endfunc

func! hearth#lint#errors#Unpack(lint)
    " Extract the error [type, info] (both strings) from the
    " given lint dictionary.
    let data = split(a:lint.nr, ':')
    if len(data) < 2
        " not created by us
        return [ '', '' ]
    endif
    return data
endfunc

func! hearth#lint#errors#Exists(lint)
    " Check if the given lint has hearth error data on it
    return has_key(a:lint, 'nr') && a:lint.nr != -1
endfunc

func! hearth#lint#errors#Expand(lint)
    " Given a lint entry (as sent to ALE, or used in the loclist)
    " expand it with extra info for more useful rendering
    let match = matchlist(a:lint.text, '^Unable to resolve \(\w*\): \(.*\) in')
    if !empty(match)
        let kind = match[1]
        let symbol = match[2]
        if a:lint.col > 1
            let a:lint.end_col = a:lint.col + len(symbol)
        endif
        call hearth#lint#errors#Pack(a:lint, 'symbol', symbol)
        return a:lint
    endif

    let match = matchlist(a:lint.text, '^Use of undeclared Var \(.*\)')
    if !empty(match)
        let symbol = match[1]
        if a:lint.col > 1
            let a:lint.end_col = a:lint.col + len(symbol)
        endif
        call hearth#lint#errors#Pack(a:lint, 'var', symbol)
        return a:lint
    endif

    let match = matchlist(a:lint.text, '^No such namespace: \([^ ,]*\)')
    if !empty(match)
        let ns = match[1]
        let a:lint.end_col = a:lint.col + len(ns)
        call hearth#lint#errors#Pack(a:lint, 'ns', ns)
        return a:lint
    endif

    let match = matchlist(a:lint.text, 'Invalid keyword: ::\([^/]*\)/\([^.]*\)\.')
    if !empty(match)
        let ns = match[1]
        let name = match[2]
        let a:lint.end_col = a:lint.col - 1
        let a:lint.col = a:lint.col - len(ns) - len(name) - 1
        call hearth#lint#errors#Pack(a:lint, 'ns', ns)
        return a:lint
    endif

    let match = matchlist(a:lint.text, '^EOF.*, starting at line \(\d*\)')
    if !empty(match)
        let line = match[1]
        let a:lint.lnum = line
        return a:lint
    endif

    let match = matchlist(a:lint.text, '^\(.\+\) already refers to')
    if !empty(match)
        let symbol = match[1]
        call hearth#lint#errors#Pack(a:lint, 'dup-refer', symbol)
        return a:lint
    endif

    return a:lint
endfunc
