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

func! hearth#lint#fix#symbol#Fix(bufnr, context, symbol)
    let candidates = s:findCandidateSymbols(a:symbol)
    if type(candidates) != v:t_list
        return
    endif

    " find *unique* namespaces
    let namespaces = map(candidates, 'v:val.ns')
    let unique = {}
    for ns in namespaces
        let unique[ns] = 1
    endfor

    return hearth#choose#OneOf(keys(unique), { chosenNs ->
            \ hearth#lint#fix#refers#Insert(
            \ a:context,
            \ chosenNs, 'refer', a:symbol
            \ )
        \ }, hearth#ale#Defer().thenCleanup(a:context))
endfunc
