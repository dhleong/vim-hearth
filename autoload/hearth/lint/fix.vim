
let s:fixers = {
    \ 'dup-refer': function('hearth#lint#fix#dup_refer#Fix'),
    \ 'ns': function('hearth#lint#fix#ns#Fix'),
    \ 'symbol': function('hearth#lint#fix#symbol#Fix'),
    \ 'var': function('hearth#lint#fix#var#Fix'),
    \ }

func! hearth#lint#fix#Fix(bufnr, lines)
    let lints = ale#engine#GetLoclist(a:bufnr)
    let lints = filter(copy(lints), 'v:val.linter_name ==# "hearth"')

    if !len(lints) || !has_key(lints[0], 'nr') || lints[0].nr == -1
        return
    endif

    let [ type, info ] = split(lints[0].nr, ':')
    if !has_key(s:fixers, type)
        return
    endif

    " the index in context.lines of the lint is lnum - 1,
    " since lnum is 1-indexed
    let index = lints[0].lnum - 1
    let context = {
        \ 'bufnr': a:bufnr,
        \ 'lines': a:lines,
        \ 'lint': lints[0],
        \ 'line': a:lines[index],
        \ 'lineIndex': index,
        \ }
    return s:fixers[type](a:bufnr, context, info)
endfunc
