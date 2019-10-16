
func! s:resolveMissing(var)
    let candidates = hearth#util#resolve_missing#Search(a:var)
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
    let candidates = s:resolveMissing(a:var)
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
