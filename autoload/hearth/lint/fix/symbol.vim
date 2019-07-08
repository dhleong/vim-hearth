func! s:findCandidateSymbols(symbol)
    " TODO resolve-missing op from refactor-nrepl middleware could be
    " useful here?

    let matches = hearth#util#apropos#Search(a:symbol)
    if empty(matches)
        echom 'No matches for ' . a:symbol
        return
    endif

    return matches
endfunc

func! hearth#lint#fix#symbol#Fix(bufnr, lines, symbol)
    let candidates = s:findCandidateSymbols(a:symbol)

    if len(candidates) == 1
        " easy case
        let ns = candidates[0].ns
        let symbol = candidates[0].symbol
        return hearth#lint#fix#refers#Insert(a:lines, ns, 'refer', symbol)
    endif

    " TODO choose?
endfunc
