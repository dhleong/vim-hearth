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

func! hearth#util#apropos#Search(query)
    " Blocking apropos search. Maps results into a dictionary format:
    " { 'ns': 'symbol namespace',
    "   'symbol': 'the un-namespaced symbol',
    "   'doc': 'from the original result' }

    let resp = fireplace#message({
        \ 'op': 'apropos',
        \ 'query': a:query
        \ }, v:t_list)

    if !has_key(resp[0], 'apropos-matches') || empty(resp[0]['apropos-matches'])
        " can we eval apropos directly? it works in shadow-cljs...
        let request = ''
                \. '(->> (apropos "' . a:query . '")'
                \. '     (map (fn [v]'
                \. '            {:ns (namespace v)'
                \. '             :symbol (name v)})))'

        try
            silent let resp = fireplace#platform().Query(
                \ request,
                \ )
            return resp
        catch /.*/
            " apropos not available
        endtry

        return []
    endif

    return map(resp[0]['apropos-matches'], 's:dictify(v:val)')
endfunc
