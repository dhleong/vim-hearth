
func! hearth#path#DetectShadowJs()
    if expand('%:t') ==# 'shadow-cljs.edn'
        return 1
    endif

    if filereadable(expand(hearth#path#GuessRoot() . '/shadow-cljs.edn'))
        return 1
    endif

    return 0
endfunc

func! hearth#path#GuessRoot()
    if expand('%:t') ==# 'project.clj' || expand('%:t') ==# 'shadow-cljs.edn'
        return expand('%:p:h')
    endif
    let root = fnamemodify(exists('b:java_root') ? b:java_root : fnamemodify(expand('%'), ':p:s?.*\zs[\/]\(src\|test\)[\/].*??'), ':~')

    if root =~# '/src$'
        " if you're in `/src/test`, the above will return `/src` instead of `/`.
        " It'd be nice to fix the regex, but this is a simple kludge for now...
        let root = root[:-4]
    endif

    return root
endfunc

func! hearth#path#GuessPort(...)
    let default = a:0 ? a:1 : 7888

    let l:root = hearth#path#GuessRoot()
    let l:path = expand(l:root . '/.nrepl-port')
    if filereadable(l:path)
        return readfile(l:path)[0]
    endif

    " shadow-cljs?
    let l:path = expand(l:root . '/.shadow-cljs/nrepl.port')
    if filereadable(l:path)
        return readfile(l:path)[0]
    endif

    if expand('%:e') ==# 'cljs'
        " for clojurescript sources, we might be trying to connect
        "  to a figwheel port
        let l:path = l:root . '/project.clj'
        if filereadable(expand(l:path))
            let l:raw = system('cat ' . l:path . ' | ag :nrepl-port')
            if len(l:raw)
                let l:match = matchlist(l:raw, '.\{-}:nrepl-port \([0-9]\+\)')
                if len(l:match) > 1
                    return l:match[1]
                endif
            endif
        endif
    endif

    " fall back to default
    return default
endfunc

func! hearth#path#FromNs(ns, ext)
    return tr(a:ns, '-.', '_/') . '.' . a:ext
endfunc

