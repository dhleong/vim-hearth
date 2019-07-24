
func! s:errToLint(err)
    let m = matchlist(a:err, '(\([a-zA-Z0-9_.\/]*\):\(\d*\):\(\d*\))')
    if empty(m)
        return {}
    endif

    let lines = split(a:err, '\n')

    let [ _, file, line, col; _ ] = m
    let message = lines[len(lines) - 1]

    let base = {
        \   'text': message,
        \   'lnum': line,
        \   'col': col,
        \   'type': 'E',
        \ }

    return hearth#lint#errors#Expand(base)
endfunc

func! s:isCleanResponse(resp)
    if has_key(a:resp, 'err') || has_key(a:resp, 'ex')
        return 0
    endif
    return !has_key(a:resp, 'status') || a:resp.status[0] !=# 'done'
endfunc

func! hearth#lint#CheckResponse(bufnr, resp)
    " Check the response of a reload (via ns#TryRequire) for lint
    if s:isCleanResponse(a:resp)
        " all good!
        call hearth#lint#Notify(a:bufnr, [])
        return
    endif

    if !has_key(a:resp, 'err')
        " the error string is only in the err key
        return
    endif

    let err = s:errToLint(a:resp.err)
    if empty(err)
        " no errors, I guess
        call hearth#lint#Notify(a:bufnr, [])
    else
        call hearth#lint#Notify(a:bufnr, [err])
    endif
endfunc

func! hearth#lint#Notify(bufnr, lints)
    " Notify linters of our current lints
    try
        call ale#other_source#ShowResults(a:bufnr, 'hearth', a:lints)
    catch /E117/
        " no ale
    endtry
endfunc

