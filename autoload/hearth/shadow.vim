
let s:extractBuildsClj = ''
    \. '(->> (slurp "shadow-cljs.edn")'
    \. '     (clojure.edn/read-string)'
    \. '     :builds'
    \. '     keys'
    \. '     (map #(str "\"" % "\""))'
    \. '     (clojure.string/join ",")'
    \. '     (#(str "[" % "]"))'
    \. '     symbol)'

func! s:isIgnoredBuildId(id)
    let ignored = hearth#pref#Get('ignored_build_ids', [])
    return index(ignored, a:id) != -1
endfunc

func! s:extractBuilds()
    " NOTE: make sure we talk to clj; if we just use platform()
    " fireplace will want to use the cljs repl, but we haven't
    " connected yet, and we need the system-level clojure context
    " to be able to read the edn file anyway
    let resp = fireplace#clj().Message({
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
    return filter(builds, '!s:isIgnoredBuildId(v:val)')
endfunc

func! s:activateBuild(port, id)
    let request = '(cider.piggieback/cljs-repl ' . a:id . ')'
    let result = fireplace#clj().Query(request)
    if len(result) && result[0] ==# 'no-worker'
        " TODO prompt to start?
        echo "No worker started for build: " . result[1]
        return
    endif

    " the piggieback call seems to still be needed for fireplace to know that
    " the cljs repl is ready
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
