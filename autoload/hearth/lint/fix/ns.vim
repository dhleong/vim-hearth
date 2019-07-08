let s:commonAliases = {
    \ 'io': 'clojure.java.io',
    \ 's': 'clojure.spec.alpha',
    \ 'str': 'clojure.string',
    \ }

func! s:findCandidateNs(alias)
    " TODO namespace-aliases op from refactor-nrepl middleware could be
    " useful?

    let resp = fireplace#message({
        \ 'op': 'apropos',
        \ 'query': a:alias
        \ })

    if !has_key(resp[0], 'apropos-matches')
        echom 'No matches for ' . a:alias
        return
    endif

    let matches = resp[0]['apropos-matches']
    let expected = '\H' . a:alias . '/'
    let candidates = filter(matches, 'v:val.name =~# expected')

    " find all *unique* namespace candidates
    let namespaces = {}
    for c in candidates
        let ns = c.name[0:stridx(c.name, '/')-1]
        let namespaces[ns] = 1
    endfor

    if has_key(s:commonAliases, a:alias)
        let namespaces[s:commonAliases[a:alias]] = 1
    endif

    return keys(namespaces)
endfunc

func! hearth#lint#fix#ns#Fix(bufnr, lines, alias)
    let namespaces = s:findCandidateNs(a:alias)

    if len(namespaces) == 1
        " easy case
        let ns = namespaces[0]
        return hearth#lint#fix#refers#Insert(a:lines, ns, 'as', a:alias)
    endif
endfunc
