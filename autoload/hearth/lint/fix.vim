
let s:fixers = {
    \ 'ns': function('hearth#lint#fix#ns#Fix'),
    \ 'symbol': function('hearth#lint#fix#symbol#Fix'),
    \ }

func! hearth#lint#fix#Fix(bufnr, lines)
    let lints = ale#engine#GetLoclist(a:bufnr)
    let lints = filter(lints, 'v:val.linter_name ==# "hearth"')

    if !len(lints) || !has_key(lints[0], 'nr') || lints[0].nr == -1
        return
    endif

    let [ type, info ] = split(lints[0].nr, ':')
    if !has_key(s:fixers, type)
        return
    endif

    return s:fixers[type](a:bufnr, a:lines, info)
endfunc
