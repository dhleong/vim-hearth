
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
    " NOTE: since this (typically) gets called *before* we've set up the
    " Piggieback layer, we can't use fireplace#message directly, since
    " fireplace#client throws when used from cljs files without Piggieback.
    " It's simple enough to use platform() directly for this special case
    let resp = fireplace#platform().message({
        \ 'op': 'eval',
        \ 'code': s:extractBuildsClj,
        \ 'session': 0,
        \ }, v:t_dict)
    if empty(resp) || !has_key(resp, 'value')
        return []
    endif

    let builds = []
    for rawList in resp.value
        let builds += eval(rawList)
    endfor
    return builds
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
