func! s:filter(results)
    return filter(a:results, 'hearth#util#search#IsAcceptableNs(v:val.name)')
endfunc

func! hearth#util#resolve_missing#Search(var)
    if !fireplace#op_available('resolve-missing')
        " avoid the roundtrip if we know the middleware is unavailable
        return []
    endif

    let resp = fireplace#message({
        \ 'op': 'resolve-missing',
        \ 'symbol': a:var,
        \ }, v:t_dict)
    if empty(resp) || !has_key(resp, 'candidates')
        return []
    endif

    " the response is a stringified list of maps; this is hacky, but
    " we can munge it into a vim structure:
    let raw = resp['candidates']
    if type(raw) == v:t_list
        return s:filter(raw)
    endif

    let raw = substitute(raw, ':\(name\|type\) ', '"\1": "', 'g')
    let raw = substitute(raw, ', ', '", ', 'g')
    let raw = substitute(raw, '}', '"},', 'g')
    return s:filter(eval('[' . raw[1:-2] . ']'))
endfunc
