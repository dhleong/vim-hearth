let s:commonAliases = {
    \ 'io': 'clojure.java.io',
    \ 's': 'clojure.spec.alpha',
    \ 'str': 'clojure.string',
    \ }

func! s:findKnownNsForAlias(bufnr, alias)
    if !fireplace#op_available('namespace-aliases')
        " avoid the roundtrip if we know the middleware is unavailable
        return
    endif

    let resp = fireplace#message({
        \ 'op': 'namespace-aliases',
        \ 'serialization-format': 'bencode',
        \ }, v:t_list)
    if empty(resp) || !has_key(resp[0], 'namespace-aliases')
        return
    endif

    " refactor-nrepl returns a map of {type -> {alias -> [ns...]}}
    let m = resp[0]['namespace-aliases']

    let type = expand('#' . a:bufnr . ':e')
    if !has_key(m, type) || !has_key(m[type], a:alias)
        " no aliases for our filetype, or no matching alias
        return
    endif

    " per the documentation, the first item in the list of namespaces
    " is the best match
    let candidates = m[type][a:alias]

    " I'm not sure why refactor-nrepl uses a / for the last part in the
    " namespace, but clean it up
    return substitute(candidates[0], '/', '.', 'g')
endfunc

func! s:findCandidateNs(bufnr, context, alias)
    " attempt to find a definitive answer using refactor-nrepl, if available
    let existing = s:findKnownNsForAlias(a:bufnr, a:alias)
    if type(existing) == v:t_string
        return [existing]
    elseif type(existing) == v:t_list
        return existing
    endif

    let namespaces = {}
    let matches = hearth#util#apropos#Search(a:alias . '/')
    if !empty(matches)
        let candidates = hearth#lint#fix#ns#FilterApropos(a:context, matches, a:alias)

        " find all *unique* namespace candidates
        for c in candidates
            let namespaces[c.ns] = 1
        endfor
    endif

    if has_key(s:commonAliases, a:alias)
        let namespaces[s:commonAliases[a:alias]] = 1
    endif

    return keys(namespaces)
endfunc

func! hearth#lint#fix#ns#FilterApropos(context, matches, alias)
    let expected = '\%(\<\|.\)' . a:alias . '$'
    let candidates = filter(a:matches, 'v:val.ns =~# expected')
    if len(candidates) <= 1
        return candidates
    endif

    " if they've started typing
    let m = matchlist(a:context.line, a:alias . '/\([a-zA-Z-]\+\>\)')
    if len(m) > 1
        let expected = '^' . m[1]
        let candidates = filter(candidates, 'v:val.symbol =~# expected')
    endif

    return candidates
endfunc

func! hearth#lint#fix#ns#Fix(bufnr, context, alias)
    let namespaces = s:findCandidateNs(a:bufnr, a:context, a:alias)
    if empty(namespaces)
        echom 'No matches for ' . a:alias
        return
    endif

    return hearth#choose#OneOf(namespaces, { ns ->
            \ hearth#lint#fix#refers#Insert(a:context, ns, 'as', a:alias)
        \ }, hearth#ale#Defer().thenCleanup(a:context))
endfunc
