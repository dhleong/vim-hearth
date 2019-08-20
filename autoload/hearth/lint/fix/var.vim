
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

    " looks like a full ns/var ref; try requiring the ns
    return hearth#lint#fix#ns#Fix(a:bufnr, a:context, varNs)
endfunc
