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
    if type(candidates) != v:t_list
        return
    endif

    let namespaces = map(candidates, 'v:val.ns')
    return hearth#choose#OneOf(namespaces, { chosenNs ->
            \ hearth#lint#fix#refers#Insert(
            \ a:lines,
            \ chosenNs, 'refer', a:symbol
            \ )
        \ }, hearth#ale#Defer())
endfunc
