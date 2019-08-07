
func! hearth#lint#fix#var#Fix(bufnr, context, var)
    let nsSeparator = stridx(a:var, '/')
    if nsSeparator == -1
        return hearth#lint#fix#symbol#Fix(a:bufnr, a:context, a:var)
    endif
    return hearth#lint#fix#ns#Fix(a:bufnr, a:context, a:var[:nsSeparator-1])
endfunc
