
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
    return fnamemodify(exists('b:java_root') ? b:java_root : fnamemodify(expand('%'), ':p:s?.*\zs[\/]\(src\|test\)[\/].*??'), ':~')
endfunc

func! hearth#path#GuessPort(...)
    let default = a:0 ? a:1 : 7888

    let l:root = hearth#path#GuessRoot()
    let l:path = l:root . '/.nrepl-port'
    if filereadable(expand(l:path))
        return system('cat ' . l:path)
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

