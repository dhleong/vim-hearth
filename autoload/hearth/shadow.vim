
let s:extractBuildsClj = ''
    \. '(->> (clojure.core/slurp "shadow-cljs.edn")'
    \. '     (clojure.edn/read-string)'
    \. '     :builds'
    \. '     clojure.core/keys'
    \. '     (clojure.core/map #(str "\"" % "\""))'
    \. '     (clojure.string/join ",")'
    \. '     (#(str "[" % "]"))'
    \. '     symbol)'

func! s:extractBuilds()
    let resp = fireplace#platform().message({
        \ 'op': 'eval',
        \ 'code': s:extractBuildsClj,
        \ })
    if empty(resp) || !has_key(resp[0], 'value')
        return []
    endif

    return eval(resp[0].value)
endfunc

func! s:activateBuild(port, id)
    exe 'Piggieback ' . a:id

    " redraw first to clear fireplace's repl and avoid 'press enter' prompt
    redraw
    echo 'Connected to shadow-cljs' . a:id . ' on port ' . a:port
endfunc

func! hearth#shadow#SelectBuild(port)
    let builds = s:extractBuilds()
    if empty(builds)
        echom 'No shadow-cljs builds'
        return
    endif

    call hearth#choose#OneOf(builds, function('s:activateBuild', [a:port]))
endfunc
