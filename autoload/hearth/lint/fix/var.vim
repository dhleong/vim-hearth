
func! s:resolveMissing(bufnr, var)
    if !fireplace#op_available('resolve-missing')
        " avoid the roundtrip if we know the middleware is unavailable
        return
    endif

    let resp = fireplace#message({
        \ 'op': 'resolve-missing',
        \ 'symbol': a:var,
        \ }, v:t_dict)
    if empty(resp) || !has_key(resp, 'candidates')
        return
    endif

    " the response is a stringified list of maps; this is hacky, but
    " we can munge it into a vim structure:
    let raw = resp['candidates']
    let raw = substitute(raw, ':\(name\|type\) ', '"\1": "', 'g')
    let raw = substitute(raw, '\(, \|}\)', '"\1', 'g')
    let candidates = eval('[' . raw[1:-2] . ']')

    return filter(candidates, 'v:val.type ==# ":ns"')
endfunc

func! hearth#lint#fix#var#Fix(bufnr, context, var)
    let nsSeparator = stridx(a:var, '/')
    if nsSeparator == -1
        return hearth#lint#fix#symbol#Fix(a:bufnr, a:context, a:var)
    endif

    let varNs = a:var[:nsSeparator-1]
    if varNs ==# a:context.ns
        " probably a simple unqualified var ref, since the
        " ns assigned to the var is the current ns
        let varName = a:var[nsSeparator+1:]
        return hearth#lint#fix#symbol#Fix(a:bufnr, a:context, varName)
    endif

    " try the resolve-missing op if available (ns search doesn't work
    " very well in shadow-cljs, currently)
    let candidates = s:resolveMissing(a:bufnr, a:var)
    if type(candidates) == v:t_list && len(candidates)
        " use them!
        let namespaces = map(candidates, 'v:val.name')
        return hearth#choose#OneOf(namespaces, { ns ->
                \ hearth#lint#fix#refers#Insert(a:context, ns, 'as', varNs)
            \ }, hearth#ale#Defer().thenCleanup(a:context))
    endif

    " looks like a full ns/var ref; try requiring the ns
    return hearth#lint#fix#ns#Fix(a:bufnr, a:context, varNs)
endfunc
