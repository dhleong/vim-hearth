func! s:cljErrToLint(err) " {{{
    let m = matchlist(a:err, '(\([a-zA-Z0-9_.\/]*\):\(\d*\):\(\d*\))')
    if empty(m)
        return {}
    endif

    let lines = split(a:err, '\n')

    let [ _, file, line, col; _ ] = m
    let message = lines[len(lines) - 1]

    return {
        \   'text': message,
        \   'lnum': line,
        \   'col': col,
        \   'type': 'E',
        \ }
endfunc " }}}

func! s:figwheelErrToLint(err) "{{{
    let m = matchlist(a:err, 'WARNING: \(.*\) at line \(\d\+\)')
    if empty(m)
        return {}
    endif

    let [ _, message, line; _ ] = m
    return {
        \   'text': message,
        \   'lnum': line,
        \   'col': 1,
        \   'type': 'E',
        \ }
endfunc "}}}

func! s:errToLint(err)
    let lint = s:cljErrToLint(a:err)

    if empty(lint)
        " couldn't parse as a clj error; maybe figwheel?
        let lint = s:figwheelErrToLint(a:err)
    endif

    if empty(lint)
        " if it's still empty, there's nothing more we can do
        return lint
    endif

    return hearth#lint#errors#Expand(lint)
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

