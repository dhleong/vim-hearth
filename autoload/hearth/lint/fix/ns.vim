let s:commonAliases = {
    \ 'io': 'clojure.java.io',
    \ 's': 'clojure.spec.alpha',
    \ 'str': 'clojure.string',
    \ }

func! s:findCandidateNs(alias)
    " TODO namespace-aliases op from refactor-nrepl middleware could be
    " useful?

    let matches = hearth#util#apropos#Search(a:alias . '/')
    if empty(matches)
        echom 'No matches for ' . a:alias
        return
    endif

    let expected = '\<' . a:alias . '$'
    let candidates = filter(matches, 'v:val.ns =~# expected')

    " find all *unique* namespace candidates
    let namespaces = {}
    for c in candidates
        let namespaces[c.ns] = 1
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
