
let s:fixers = {
    \ 'dup-refer': function('hearth#lint#fix#dup_refer#Fix'),
    \ 'ns': function('hearth#lint#fix#ns#Fix'),
    \ 'symbol': function('hearth#lint#fix#symbol#Fix'),
    \ 'var': function('hearth#lint#fix#var#Fix'),
    \ }

func! s:typeOf(lint)
    let [ type, _ ] = hearth#lint#errors#Unpack(a:lint)
    return type
endfunc

func! s:fixLint(bufnr, lines, lint)
    let lint = a:lint
    if !has_key(lint, 'nr') || lint.nr == -1
        return
    endif

    let [ type, info ] = hearth#lint#errors#Unpack(lint)
    if !has_key(s:fixers, type)
        return
    endif

    " the index in context.lines of the lint is lnum - 1,
    " since lnum is 1-indexed
    let index = lint.lnum - 1
    let context = {
        \ 'bufnr': a:bufnr,
        \ 'lines': a:lines,
        \ 'lint': lint,
        \ 'line': a:lines[index],
        \ 'lineIndex': index,
        \ 'ns': fireplace#ns(),
        \ }
    return s:fixers[type](a:bufnr, context, info)
endfunc

func! hearth#lint#fix#Fix(bufnr, lines)
    let lints = ale#engine#GetLoclist(a:bufnr)
    let kondo = filter(copy(lints), 'v:val.linter_name ==# "clj-kondo"')
    let lints = filter(copy(lints), 'v:val.linter_name ==# "hearth"')

    if !empty(kondo)
        " if we have any lints from clj-kondo, see if there's anything
        " we can do about them
        let kondoFilled = hearth#lint#kondo#Extract(kondo)
        let lints = lints + kondoFilled
    endif

    if !len(lints)
        return
    elseif len(lints) == 1
        " easy case
        return s:fixLint(a:bufnr, a:lines, lints[0])
    endif

    let target = lints[0]

    if s:typeOf(target) ==# 'ns'
        " var is easier to fix than ns; try to find it
        for lint in lints[1:]
            if lint.lnum == target.lnum && s:typeOf(lint) ==# 'var'
                return s:fixLint(a:bufnr, a:lines, lint)
            endif
        endfor
    endif

    return s:fixLint(a:bufnr, a:lines, target)
endfunc
