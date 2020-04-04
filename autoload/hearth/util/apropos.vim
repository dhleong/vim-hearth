func! s:dictify(v)
    let separator = stridx(a:v.name, '/')
    let ns = a:v.name[: separator-1]
    let sym = a:v.name[separator+1:]
    return {
        \ 'ns': ns,
        \ 'symbol': sym,
        \ 'doc': a:v.doc,
        \ }
endfunc

func! s:filter(results)
    return filter(a:results, 'hearth#util#search#IsAcceptableNs(v:val.ns)')
endfunc

func! hearth#util#apropos#Search(query)
    " Blocking apropos search. Maps results into a dictionary format:
    " { 'ns': 'symbol namespace',
    "   'symbol': 'the un-namespaced symbol',
    "   'doc': 'from the original result' }

    " prefer eval'ing apropos directly; it seems to get better results
    " in shadow-cljs
    let request = ''
          \. '(->> (apropos "' . a:query . '")'
          \. '     (map (fn [v]'
          \. '            {:ns (namespace v)'
          \. '             :symbol (name v)})))'

    try
      silent let resp = fireplace#platform().Query(
            \ request,
            \ )

      if !empty(resp)
        return s:filter(resp)
      endif
    catch /.*/
      " apropos not available
    endtry

    let resp = fireplace#message({
        \ 'op': 'apropos',
        \ 'query': a:query
        \ }, v:t_list)

    if !has_key(resp[0], 'apropos-matches') || empty(resp[0]['apropos-matches'])
        return []
    endif

    return s:filter(map(resp[0]['apropos-matches'], 's:dictify(v:val)'))
endfunc
