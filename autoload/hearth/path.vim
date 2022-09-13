func! hearth#path#DetectBabashka()
    return getline(1) =~# '^#!/usr/bin/env bb'
endfunc

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

    " try looking for a project config file:
    let config = findfile('shadow-cljs.edn')
    if empty(config)
        let config = findfile('project.clj')
    endif
    if !empty(config)
        " found it! that should be the root
        return fnamemodify(config, ':h')
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
    let l:extension = expand('%:e')
    let l:root = hearth#path#GuessRoot()
    let l:nreplPath = expand(l:root . '/.nrepl-port')

    " shadow-cljs?
    let l:shadowPath = expand(l:root . '/.shadow-cljs/nrepl.port')
    if filereadable(l:shadowPath)
        let l:useShadow = 1

        if l:extension ==# 'clj' && filereadable(l:nreplPath)
            let l:useShadow = 0
            let l:sourcePaths = hearth#shadow#GetSourcePaths(l:root)
            let l:currentFile = expand('%:p')
            for l:path in l:sourcePaths
                if currentFile[0:len(l:path)] ==# l:path
                    let l:useShadow = 1
                    break
                endif
            endfor

            " TODO: Check that the file is actually in a :source-path
        endif

        if l:useShadow
            return readfile(l:shadowPath)[0]
        endif
    endif

    if l:extension ==# 'cljs' || l:extension ==# 'cljc'
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

    " Standard nrepl
    if filereadable(l:nreplPath)
        return readfile(l:nreplPath)[0]
    endif

    " Babashka single-file script?
    if hearth#path#DetectBabashka()
        " Babashka nrepl-server defaults to this port
        return 1667
    endif

    " fall back to default
    return default
endfunc

func! hearth#path#FromNs(ns, ext)
    return tr(a:ns, '-.', '_/') . '.' . a:ext
endfunc

func! hearth#path#FileFromNs(ns, ext)
    let path = fireplace#path()
    let relative = hearth#path#FromNs(a:ns, a:ext)
    for f in path
        let fullPath = f . '/' . relative
        if filereadable(fullPath)
            return fullPath
        endif
    endfor
endfunc
