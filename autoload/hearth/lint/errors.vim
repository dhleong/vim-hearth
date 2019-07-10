
func! hearth#lint#errors#Expand(lint)
    " Given a lint entry (as sent to ALE, or used in the loclist)
    " expand it with extra info for more useful rendering
    let match = matchlist(a:lint.text, '^Unable to resolve \(\w*\): \(.*\) in')
    if !empty(match)
        let kind = match[1]
        let symbol = match[2]
        let a:lint.end_col = a:lint.col + len(symbol)
        let a:lint.nr = 'symbol:' . symbol
        return a:lint
    endif

    let match = matchlist(a:lint.text, '^No such namespace: \(.*\)')
    if !empty(match)
        let ns = match[1]
        let a:lint.end_col = a:lint.col + len(ns)
        let a:lint.nr = 'ns:' . ns
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
        let a:lint.nr = 'dup-refer:' . symbol
        return a:lint
    endif

    return a:lint
endfunc
